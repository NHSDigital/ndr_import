require 'ndr_import/mapper'
require 'active_support/core_ext/hash'

module NdrImport
  # This class maintains the state of a table mapping and encapsulates the logic
  # required to transform a table of data into "records". Particular attention
  # has been made to use enumerables throughout to help with the transformation
  # of large quantities of data.
  # rubocop:disable Metrics/ClassLength
  class Table
    include NdrImport::Mapper

    def self.all_valid_options
      %w[canonical_name delimiter liberal_parsing filename_pattern file_password last_data_column
         tablename_pattern header_lines footer_lines format klass columns slurp row_identifier
         significant_mapped_fields]
    end

    def all_valid_options
      self.class.all_valid_options
    end

    attr_reader(*all_valid_options)
    attr_accessor :notifier, :table_metadata

    def initialize(options = {})
      options.stringify_keys! if options.is_a?(Hash)
      validate_options(options)

      all_valid_options.each do |key|
        # This pattern is used to only set attributes if option specified,
        # which makes for more concise YAML serialization.
        options[key] && instance_variable_set("@#{key}", options[key])
      end

      @row_index = 0
    end

    def match(filename, tablename)
      ::File.basename(filename) =~ (filename_pattern || /\A.*\z/) &&
        (tablename.nil? || tablename =~ (tablename_pattern || /\A.*\z/))
    end

    # This method transforms a table of data, given a line array/enumerator and yields
    # klass, fields and index (input row number) for each record that it would create
    # as a result of the transformation process.
    def transform(lines, &block)
      return enum_for(:transform, lines) unless block

      @row_index = 0
      @header_valid = false
      @header_best_guess = nil
      @notifier.try(:started)

      last_col = last_column_to_transform
      skip_footer_lines(lines, footer_lines).each do |line|
        line.is_a?(Array) ? process_line(line[0..last_col], &block) : process_line(line, &block)
      end

      @notifier.try(:finished)
    end

    # This method process a line of data, If it is a header line it validates it, otherwise
    # transforms it. It also increments the row index and notifies the amount of lines processed.
    def process_line(line, &block)
      return enum_for(:process_line, line) unless block

      if @row_index < header_lines
        mutate_regexp_columns(line)
        consume_header_line(line, @columns)
      else
        transform_line(line, @row_index, &block)
      end

      @row_index += 1

      # We've now seen enough lines to have consumed a valid header; is this the case?
      fail_unless_header_complete(@columns) if @row_index == header_lines

      @notifier.try(:processed, @row_index)
    end

    # Update 'column' values expressed as a regular expression
    def mutate_regexp_columns(line)
      @columns.each_with_index do |column, index|
        next unless column['column'].is_a? Regexp

        column['column'] = line[index] if line[index].match? column['column']
      end
    end

    # This method transforms an incoming line of data by applying each of the klass masked
    # mappings to the line and yielding the klass and fields for each mapped klass.
    def transform_line(line, index)
      return enum_for(:transform_line, line, index) unless block_given?

      identifier = case @row_identifier.to_s
                   when 'index'
                     index
                   when 'uuid'
                     SecureRandom.uuid
                   end

      masked_mappings.each do |klass, klass_mappings|
        fields = mapped_line(line, klass_mappings)
        fields['row_identifier'] = identifier unless identifier.nil?
        next if fields[:skip].to_s == 'true'
        yield(klass, fields, index)
      end
    end

    def header_valid?
      @header_valid == true
    end

    # For readability, we should serialise the columns last
    def encode_with(coder)
      options = self.class.all_valid_options - ['columns']
      options.each do |option|
        value = send(option)
        coder[option] = value if value
      end
      coder['columns'] = @columns
    end

    private

    # This method uses a buffer to not yield the last <buffer_size> iterations of an enumerable.
    # We use it to skip footer lines (without having to convert the enumerable to an array).
    def skip_footer_lines(lines, buffer_size)
      return enum_for(:skip_footer_lines, lines, buffer_size) unless block_given?

      buffer = []
      lines.each do |line|
        buffer.unshift(line)

        yield buffer.pop if buffer.length > buffer_size
      end
    end

    # This method memoizes the klass masked mappings. Where a table level
    # klass is defined it is used with the whole mapping, otherwise the masks are generated.
    def masked_mappings
      @masked_mappings ||= begin
        if @klass
          { @klass => @columns }
        else
          column_level_klass_masked_mappings
        end
      end
    end

    # This method generates a hash of klass based mappings, one for each defined klass
    # where the whole line mapping is masked to just the data items of that klass.
    def column_level_klass_masked_mappings
      ensure_mappings_define_klass

      # Loop through each klass
      masked_mappings = {}
      @columns.map { |mapping| mapping['klass'] }.flatten.compact.uniq.each do |klass|
        # Duplicate the column mappings and do not capture fields that relate to other klasses
        masked_mappings[klass] = mask_mappings_by_klass(klass)
      end
      masked_mappings
    end

    # This method ensures that every column mapping defines a klass (unless it is a column that
    # we do not capture). It is only used where a table level klass is not defined.
    def ensure_mappings_define_klass
      klassless_mappings = @columns.
                           select { |mapping| mapping.nil? || mapping['klass'].nil? }.
                           reject { |mapping| mapping['do_not_capture'] }.
                           map { |mapping| mapping['column'] || mapping['standard_mapping'] }

      return if klassless_mappings.empty?

      # All column mappings for the single item file require a klass definition.
      fail "Missing klass for column(s): #{klassless_mappings.to_sentence}"
    end

    # This method duplicates the mappings and applies a do_not_capture mask to those that do not
    # relate to this klass, returning the masked mappings
    def mask_mappings_by_klass(klass)
      @columns.dup.map do |mapping|
        if Array(mapping['klass']).flatten.include?(klass)
          mapping
        else
          { 'do_not_capture' => true }
        end
      end
    end

    def validate_options(hash)
      fail ArgumentError unless hash.is_a?(Hash)

      unrecognised_options = hash.keys - all_valid_options
      return if unrecognised_options.empty?
      fail ArgumentError, "Unrecognised options: #{unrecognised_options.inspect}"
    end

    # Process `line` as a candidate header row. Header validation is done
    # lazily, once all expected header lines have been consumed.
    def consume_header_line(line, column_mappings)
      columns = column_names(column_mappings)

      header_guess = line.map { |column| column.to_s.downcase }

      # The "best guess" is only if/when the header eventually deemed to be
      # invalid - in which case, it builds the informative error message.
      @header_best_guess = header_guess if header_guess.any?(&:present?)
      @header_valid      = true         if header_guess == columns
    end

    # Once all header lines have been consumed, blow up in a
    # helpful fashion if no valid row was found:
    def fail_unless_header_complete(column_mappings)
      return unless header_lines > 0 && !header_valid?

      expected_names = column_names(column_mappings)
      received_names = @header_best_guess || []

      unexpected = received_names - expected_names
      missing    = expected_names - received_names

      fail header_message_for(missing, unexpected)
    end

    def header_message_for(missing, unexpected)
      message = ['Header is not valid!']

      message << "missing: #{missing.inspect}"       if missing.any?
      message << "unexpected: #{unexpected.inspect}" if unexpected.any?
      message << '(out of order)' if missing.none? && unexpected.none?

      message.join(' ')
    end

    # returns the column names as we expect to receive them
    def column_names(column_mappings)
      column_mappings.map { |c| (c['column'] || c['standard_mapping']).try(:downcase) }
    end

    # If specified in the mapping, stop transforming data at a given index (column)
    def last_column_to_transform
      return -1 if last_data_column.nil?
      return last_data_column - 1 if last_data_column.is_a?(Integer)

      error =  "Unknown 'last_data_column' format: #{last_data_column} " \
               "(#{last_data_column.class})"
      raise error unless last_data_column.is_a?(String) && last_data_column =~ /\A[A-Z]+\z/i

      # If it's an excel column label (eg 'K', 'AF', 'DDE'), convert it to an index
      index_from_column_label
    end

    def index_from_column_label
      alphabet_index_hash = ('A'..'Z').map.with_index.to_h
      index = last_data_column.upcase.chars.inject(0) do |char_index, char|
        (char_index * 26) + (alphabet_index_hash[char] + 1)
      end
      index - 1
    end
  end # class Table
  # rubocop:enable Metrics/ClassLength
end
