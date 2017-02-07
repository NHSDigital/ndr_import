require 'ndr_support/string/cleaning'
require 'ndr_support/string/conversions'
require 'ndr_import/standard_mappings'
require 'base64'
require 'msworddoc-extractor'

# This module provides helper logic for mapping unified sources for import into the system
module NdrImport::Mapper
  private

  # uses the mappings for this line to unpack the fixed width string
  # returning an array of the resulting columns
  def fixed_width_columns(line, line_mappings)
    unpack_patterns = line_mappings.map { |c| c['unpack_pattern'] }.join
    line.unpack(unpack_patterns)
  end

  # the replace option can be used before any other mapping option
  def replace_before_mapping(original_value, field_mapping)
    return unless original_value && field_mapping.include?('replace')

    replaces = field_mapping['replace']

    if replaces.is_a?(Array)
      replaces.each { |repls| apply_replaces(original_value, repls) }
    else
      apply_replaces(original_value, replaces)
    end
  end

  def apply_replaces(value, replaces)
    if value.is_a?(Array)
      value.each { |val| apply_replaces(val, replaces) }
    else
      replaces.each { |pattern, replacement| value.gsub!(pattern, replacement) }
    end
  end

  # Returns the standard_mapping hash specified
  # Assumes mapping exists
  def standard_mapping(mapping_name, column_mapping)
    standard_mapping = NdrImport::StandardMappings.mappings[mapping_name]
    return unless standard_mapping

    column_mapping.each_with_object(standard_mapping.dup) do |(key, value), result|
      if 'mappings' == key
        # Column mapping appends mappings to the standard mapping...
        result[key] += value
      else
        # ...but overwrites other values.
        result[key] = value
      end
    end
  end

  # This takes an array of raw values and their associated mappings and returns an attribute hash
  # It accepts a block to alter the raw value that is stored in the raw text (if necessary),
  # enabling it to work for different sources
  def mapped_line(line, line_mappings)
    validate_line_mappings(line_mappings)

    rawtext = {}
    data    = {}

    line.each_with_index do |raw_value, col|
      column_mapping = line_mappings[col]
      if column_mapping.nil?
        fail ArgumentError,
             "Line has too many columns (expected #{line_mappings.size} but got #{line.size})"
      end

      next if column_mapping['do_not_capture']

      if column_mapping['standard_mapping']
        column_mapping = standard_mapping(column_mapping['standard_mapping'], column_mapping)
      end

      # Establish the rawtext column name we are to use for this column
      rawtext_column_name = (column_mapping['rawtext_name'] || column_mapping['column']).downcase

      # Replace raw_value with decoded raw_value
      Array(column_mapping['decode']).each do |encoding|
        raw_value = decode_raw_value(raw_value, encoding)
      end

      # raw value casting can vary between sources, so we allow the caller to apply it here
      if respond_to?(:cast_raw_value)
        raw_value = cast_raw_value(rawtext_column_name, raw_value, column_mapping)
      end

      # Store the raw column value
      rawtext[rawtext_column_name] = raw_value

      next unless column_mapping.key?('mappings')
      column_mapping['mappings'].each do |field_mapping|
        # create a duplicate of the raw value we can manipulate
        original_value = raw_value ? raw_value.dup : nil

        replace_before_mapping(original_value, field_mapping)
        value = mapped_value(original_value, field_mapping)

        # We don't care about blank values, unless we're mapping a :join
        # field (in which case, :compact may or may not be being used).
        next if value.blank? && !field_mapping['join']

        field = field_mapping['field']

        data[field] ||= {}
        data[field][:values] ||= [] # "better" values come earlier
        data[field][:compact]  = true unless data[field].key?(:compact)

        if field_mapping['order']
          data[field][:join] ||= field_mapping['join']
          data[field][:compact] = field_mapping['compact'] if field_mapping.key?('compact')

          data[field][:values][field_mapping['order'] - 1] = value
        elsif field_mapping['priority']
          data[field][:values][field_mapping['priority']] = value
        else
          data[field][:values].unshift(value) # new "best" value
        end
      end
    end

    attributes = {}

    # tidy up many to one field mappings
    # and one to many, for cross-populating
    data.each do |field, field_data|
      values = field_data[:values]

      attributes[field] =
        if field_data.key?(:join)
          # Map "blank" values to nil:
          values = values.map { |value| value if value.present? }
          values.compact! if field_data[:compact]
          values.join(field_data[:join])
        else
          values.detect(&:present?)
        end
    end

    attributes[:rawtext] = rawtext # Assign last
    attributes
  end

  def mapped_value(original_value, field_mapping)
    if field_mapping.include?('format')
      begin
        return original_value.blank? ? nil : original_value.to_date(field_mapping['format'])
      rescue ArgumentError => e
        e2 = ArgumentError.new("#{e} value #{original_value.inspect}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    elsif field_mapping.include?('clean')
      return original_value.blank? ? nil : original_value.clean(field_mapping['clean'])
    elsif field_mapping.include?('map')
      return field_mapping['map'].fetch(original_value, original_value)
    elsif field_mapping.include?('match')
      # WARNING:TVB Thu Aug  9 17:09:25 BST 2012 field_mapping['match'] regexp
      # may need to be escaped
      matches = Regexp.new(field_mapping['match']).match(original_value)
      return matches[1].strip if matches && matches.size > 0
    elsif field_mapping.include?('daysafter')
      return original_value unless original_value.to_i.to_s == original_value.to_s
      return original_value.to_i.days.since(field_mapping['daysafter'].to_time).to_date
    else
      return nil if original_value.blank?
      return original_value.is_a?(String) ? original_value.strip : original_value
    end
  end

  # Check for duplicate priorities, check for nonexistent standard_mappings
  def validate_line_mappings(line_mappings)
    priority = {}
    line_mappings.each do |column_mapping|
      if column_mapping['standard_mapping']
        if standard_mapping(column_mapping['standard_mapping'], column_mapping).nil?
          fail "Standard mapping \"#{column_mapping['standard_mapping']}\" does not exist"
        end
      end

      next unless column_mapping.key?('mappings')
      column_mapping['mappings'].each do |field_mapping|
        field = field_mapping['field']
        if field_mapping['priority']
          fail 'Cannot have duplicate priorities' if priority[field] == field_mapping['priority']
          priority[field] = field_mapping['priority']
        else
          priority[field] = 1
        end
      end
    end
    true
  end

  # Decode raw_value using specified encoding
  # E.g. adding decode to a column:
  #
  # - column: base64
  #   decode:
  #   - :base64
  #   - :word_doc
  #
  # would base64 decode a word document and then 'decode' the word document into plain text
  def decode_raw_value(raw_value, encoding)
    case encoding
    when :base64
      Base64.decode64(raw_value)
    when :word_doc
      read_word_stream(StringIO.new(raw_value, 'r'))
    else
      fail "Cannot decode: #{encoding}"
    end
  end

  # Given an IO stream representing a .doc word document,
  # this method will extract the text for the document in the same way
  # as NdrImport::Helpers::File::Word#read_word_file
  def read_word_stream(stream)
    # whole_contents adds "\n" to end of stream, we remove it
    MSWordDoc::Extractor.load(stream).whole_contents.sub(/\n\z/, '')
  end
end
