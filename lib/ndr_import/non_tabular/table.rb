require 'ndr_import/table'

module NdrImport
  module NonTabular
    # This class maintains the state of a non tabular table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      require 'i18n'
      require 'ndr_support/regexp_range' # TODO: unneeded?
      require 'ndr_support/utf8_encoding'
      require 'ndr_import/non_tabular/column_mapping'
      require 'ndr_import/non_tabular/record'
      require 'ndr_import/non_tabular/line'

      include UTF8Encoding

      TABULAR_ONLY_OPTIONS = %w[delimiter last_data_column liberal_parsing tablename_pattern
                                header_lines footer_lines slurp].freeze

      NON_TABULAR_OPTIONS = %w[capture_end_line capture_start_line start_line_pattern
                               end_line_pattern remove_lines start_in_a_record
                               end_in_a_record].freeze

      def self.all_valid_options
        super - TABULAR_ONLY_OPTIONS + NON_TABULAR_OPTIONS
      end

      attr_reader(*NON_TABULAR_OPTIONS)
      attr_reader :non_tabular_lines

      def header_lines
        0
      end

      def footer_lines
        0
      end

      def initialize(options = {})
        super(options)

        validate_presence_of_start_line_pattern
      end

      def tablename_pattern=(_value)
        fail NdrImport::MappingError, 'Should not define tablename_pattern'
      end

      def validate_presence_of_start_line_pattern
        return if @start_line_pattern
        fail NdrImport::MappingError,
             I18n.t('mapping.errors.missing_start_line_pattern')
      end

      # This method transforms a table of data, given a line array/enumerator and yields
      # klass, fields and index (input row number) for each record that it would create
      # as a result of the transformation process.
      def transform(lines, &block)
        return enum_for(:transform, lines) unless block

        self.non_tabular_lines = ensure_utf8_enum!(lines)
        remove_unwanted_lines

        super(read_non_tabular_array, &block)
      end

      def validate_header(_line, _column_mappings)
        @header_valid = true
      end

      protected

      def ensure_utf8_enum!(lines)
        return enum_for(:ensure_utf8_enum!, lines) unless block_given?

        lines.each do |line|
          # puts 'ensure_utf8_object!'
          yield ensure_utf8_object!(line)
        end
      end

      # This method flages unwanted lines, typically page headers and footers as removed
      # preventing them from being captured in the non tabular record. Especially useful
      # when there page headers and footers that are out of step with the start and end
      # of each record and could therefore appear anywhere in an individual record if kept.
      def remove_unwanted_lines
        return unless @remove_lines.is_a?(Hash)
        @non_tabular_lines.each_with_index do |_line, i|
          @remove_lines.each do |_key, lines_to_remove|
            comparable_lines = @non_tabular_lines[i, lines_to_remove.length]
            next unless lines_equal(comparable_lines, lines_to_remove)
            # All lines are equal, so flag them as removed
            comparable_lines.each { |line| line.removed = true }
          end
        end
      end

      def read_non_tabular_array
        @tabular_array = []
        @in_a_record = @start_in_a_record
        @non_tabular_record = NdrImport::NonTabular::Record.new

        partition_and_process_non_tabular_lines
        process_end_of_record

        @tabular_array
      end

      # Reads the array of lines, looking to see if a line matches the start_line_pattern,
      # identifying the start of a record. It then collects all the lines until a line
      # matches the end_line_pattern (if defined, otherwise when it matches the next
      # start_line_pattern) and sends these line to NdrImport::NonTabular::Record#tabulate.
      #
      # NOTE: Currently the end line is consumed and does not form part of the
      # collected array.
      def partition_and_process_non_tabular_lines
        non_tabular_lines.each do |line|
          if line =~ @start_line_pattern
            # This is a start line
            start_record(line)
          elsif line =~ @end_line_pattern
            # This is an end line
            end_record(line)
          else
            @non_tabular_record << line if @in_a_record
          end
        end
      end

      # Checks to see if we get the start of a new record before getting the end of the previous
      # one and fails if so. Otherwise it tabulates the previous record
      def start_record(line)
        if @end_line_pattern
          fail NdrImport::MappingError,
               I18n.t('mapping.errors.start_pattern_before_end') if @in_a_record
        else
          # No endline mapping
          @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        end
        @non_tabular_record = NdrImport::NonTabular::Record.new
        @non_tabular_record << line if @capture_start_line
        @in_a_record = true
      end

      # Tabulate the record (if in one), flagged it as no longer being in a record
      # and set the record to be a new one.
      def end_record(line)
        # Add the end line to the @non_tabular_record (if required) before ending the record
        @non_tabular_record << line if @capture_end_line
        @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        @in_a_record = false
        @non_tabular_record = NdrImport::NonTabular::Record.new
      end

      # If the non-tabular data ends in a record (i.e. the last record is terminated by the EOF)
      # then we need to process the last record manually or flag those lines as not being part
      # of a record
      def process_end_of_record
        return if @non_tabular_record.empty?
        if @end_in_a_record
          @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        else
          @non_tabular_record.not_a_record!
        end
      end

      # Store the source lines as instances of NdrImport::NonTabular::Line
      def non_tabular_lines=(lines)
        @non_tabular_lines = lines.map.with_index do |line, i|
          NdrImport::NonTabular::Line.new(line, i)
        end
      end

      # Create and memoize the column mappings
      def column_mappings
        @column_mappings ||= raw_column_mappings.map do |column_mapping|
          NdrImport::NonTabular::ColumnMapping.new(column_mapping)
        end
      end

      def raw_column_mappings
        @columns || []
      end

      # This method compares two arrays, where the first must be an array of
      # NdrImport::NonTabular::Line or string elements
      # and the second can be a mix of strings and/or regular expressions
      def lines_equal(lines, other_lines)
        return false unless lines.length == other_lines.length
        lines.each_with_index.map do |line, i|
          other_line = other_lines[i]
          other_line.is_a?(Regexp) ? line.to_s =~ other_line : line.to_s == other_line
        end.all?
      end
    end
  end
end
