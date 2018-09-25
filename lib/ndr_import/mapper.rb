require 'ndr_support/string/cleaning'
require 'ndr_support/string/conversions'
require 'ndr_import/standard_mappings'
require 'base64'
require 'msworddoc-extractor'

# This module provides helper logic for mapping unified sources for import into the system
module NdrImport::Mapper
  # The mapper runs nested loops that can result in the allocation of millions
  # of short-lived objects. By pre-allocating these known keys, we can reduce GC pressure.
  module Strings
    CLEAN            = 'clean'.freeze
    COLUMN           = 'column'.freeze
    COMPACT          = 'compact'.freeze
    DAYSAFTER        = 'daysafter'.freeze
    DECODE           = 'decode'.freeze
    DO_NOT_CAPTURE   = 'do_not_capture'.freeze
    FIELD            = 'field'.freeze
    FORMAT           = 'format'.freeze
    JOIN             = 'join'.freeze
    MAP              = 'map'.freeze
    MAPPINGS         = 'mappings'.freeze
    MATCH            = 'match'.freeze
    ORDER            = 'order'.freeze
    PRIORITY         = 'priority'.freeze
    RAWTEXT_NAME     = 'rawtext_name'.freeze
    REPLACE          = 'replace'.freeze
    STANDARD_MAPPING = 'standard_mapping'.freeze
    UNPACK_PATTERN   = 'unpack_pattern'.freeze
  end

  private

  # uses the mappings for this line to unpack the fixed width string
  # returning an array of the resulting columns
  def fixed_width_columns(line, line_mappings)
    unpack_patterns = line_mappings.map { |c| c[Strings::UNPACK_PATTERN] }.join
    line.unpack(unpack_patterns)
  end

  # the replace option can be used before any other mapping option
  def replace_before_mapping(original_value, field_mapping)
    return unless original_value && field_mapping.include?(Strings::REPLACE)

    replaces = field_mapping[Strings::REPLACE]

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
      if Strings::MAPPINGS == key
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

      next if column_mapping[Strings::DO_NOT_CAPTURE]

      if column_mapping[Strings::STANDARD_MAPPING]
        column_mapping = standard_mapping(column_mapping[Strings::STANDARD_MAPPING], column_mapping)
      end

      # Establish the rawtext column name we are to use for this column
      rawtext_column_name = (column_mapping[Strings::RAWTEXT_NAME] || column_mapping[Strings::COLUMN]).downcase

      # Replace raw_value with decoded raw_value
      Array(column_mapping[Strings::DECODE]).each do |encoding|
        raw_value = decode_raw_value(raw_value, encoding)
      end

      # raw value casting can vary between sources, so we allow the caller to apply it here
      if respond_to?(:cast_raw_value)
        raw_value = cast_raw_value(rawtext_column_name, raw_value, column_mapping)
      end

      # Store the raw column value
      rawtext[rawtext_column_name] = raw_value

      next unless column_mapping.key?(Strings::MAPPINGS)
      column_mapping[Strings::MAPPINGS].each do |field_mapping|
        # create a duplicate of the raw value we can manipulate
        original_value = raw_value ? raw_value.dup : nil

        replace_before_mapping(original_value, field_mapping)
        value = mapped_value(original_value, field_mapping)

        # We don't care about blank values, unless we're mapping a :join
        # field (in which case, :compact may or may not be being used).
        next if value.blank? && !field_mapping[Strings::JOIN]

        field = field_mapping[Strings::FIELD]

        data[field] ||= {}
        data[field][:values] ||= [] # "better" values come earlier
        data[field][:compact]  = true unless data[field].key?(:compact)

        if field_mapping[Strings::ORDER]
          data[field][:join] ||= field_mapping[Strings::JOIN]
          data[field][:compact] = field_mapping[Strings::COMPACT] if field_mapping.key?(Strings::COMPACT)

          data[field][:values][field_mapping[Strings::ORDER] - 1] = value
        elsif field_mapping[Strings::PRIORITY]
          data[field][:values][field_mapping[Strings::PRIORITY]] = value
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
    if field_mapping.include?(Strings::FORMAT)
      begin
        return original_value.blank? ? nil : original_value.to_date(field_mapping[Strings::FORMAT])
      rescue ArgumentError => e
        e2 = ArgumentError.new("#{e} value #{original_value.inspect}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    elsif field_mapping.include?(Strings::CLEAN)
      return nil if original_value.blank?

      cleaners = Array(field_mapping[Strings::CLEAN])
      return cleaners.inject(original_value) { |a, e| a.clean(e) }
    elsif field_mapping.include?(Strings::MAP)
      return field_mapping[Strings::MAP].fetch(original_value, original_value)
    elsif field_mapping.include?(Strings::MATCH)
      # WARNING:TVB Thu Aug  9 17:09:25 BST 2012 field_mapping[Strings::MATCH] regexp
      # may need to be escaped
      matches = Regexp.new(field_mapping[Strings::MATCH]).match(original_value)
      return matches[1].strip if matches && matches.size > 0
    elsif field_mapping.include?(Strings::DAYSAFTER)
      return original_value unless original_value.to_i.to_s == original_value.to_s
      return original_value.to_i.days.since(field_mapping[Strings::DAYSAFTER].to_time).to_date
    else
      return nil if original_value.blank?
      return original_value.is_a?(String) ? original_value.strip : original_value
    end
  end

  # Check for duplicate priorities, check for nonexistent standard_mappings
  def validate_line_mappings(line_mappings)
    priority = {}
    line_mappings.each do |column_mapping|
      if column_mapping[Strings::STANDARD_MAPPING]
        if standard_mapping(column_mapping[Strings::STANDARD_MAPPING], column_mapping).nil?
          fail "Standard mapping \"#{column_mapping[Strings::STANDARD_MAPPING]}\" does not exist"
        end
      end

      next unless column_mapping.key?(Strings::MAPPINGS)
      column_mapping[Strings::MAPPINGS].each do |field_mapping|
        field = field_mapping[Strings::FIELD]
        if field_mapping[Strings::PRIORITY]
          fail 'Cannot have duplicate priorities' if priority[field] == field_mapping[Strings::PRIORITY]
          priority[field] = field_mapping[Strings::PRIORITY]
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
    return raw_value if raw_value.blank?
    case encoding
    when :base64
      Base64.decode64(raw_value)
    when :word_doc
      read_word_stream(StringIO.new(raw_value, 'r'))
    else
      raise "Cannot decode: #{encoding}"
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
