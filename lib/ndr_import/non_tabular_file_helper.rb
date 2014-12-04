# encoding: UTF-8

module UnifiedSources
  module Import
    # This mixin adds (multiline) non-tabular file functionality to unified importers.
    # It provides a file reader method and method to capture the rawtext value
    # appropriately. These methods can be overridden or aliased as required.
    #
    # The YAML mapping must define the start_line_pattern which identifies the start
    # of a multiline record (or "row") and can optionally define an end_line_pattern.
    module NonTabularFileHelper
      require 'regexp_range'

      attr_reader :non_tabular_lines

      protected

      # Reads a non-tabular text file and returns an array of tabulated rows of data,
      # where each row is an array of cells.
      def read_non_tabular_file
        self.non_tabular_lines = SafeFile.readlines(filename)
        remove_unwanted_lines
        read_non_tabular_array
      end

      # Reads a string and returns an array of tabulated data. Use only for prototyping.
      def read_non_tabular_string(text)
        self.non_tabular_lines = text.split("\n")
        remove_unwanted_lines
        read_non_tabular_array
      end

      # This method flages unwanted lines, typically page headers and footers as removed
      # preventing them from being captured in the non tabular record. Especially useful
      # when there page headers and footers that are out of step with the start and end
      # of each record and could therefore appear anywhere in an individual record if kept.
      def remove_unwanted_lines
        return unless row_mapping.remove_lines.is_a?(Hash)
        @non_tabular_lines.each_with_index do |_line, i|
          row_mapping.remove_lines.each do |_key, lines_to_remove|
            comparable_lines = @non_tabular_lines[i, lines_to_remove.length]
            next unless lines_equal(comparable_lines, lines_to_remove)
            # All lines are equal, so flag them as removed
            comparable_lines.each { |line| line.removed = true }
          end
        end
      end

      def read_non_tabular_array
        @tabular_array = []
        @in_a_record = row_mapping.start_in_a_record
        @non_tabular_record = UnifiedSources::Import::NonTabular::Record.new

        partition_and_process_non_tabular_lines
        process_end_of_record

        # We change the mapping instance variable to only contain the column mappings.
        # This enables the standard mapper to work unaltered.
        @mappings = raw_column_mappings
        @tabular_array
      end

      # Reads the array of lines, looking to see if a line matches the start_line_pattern,
      # identifying the start of a record. It then collects all the lines until a line
      # matches the end_line_pattern (if defined, otherwise when it matches the next
      # start_line_pattern) and sends these line to UnifiedSources::Import::NonTabular::Record#tabulate.
      #
      # NOTE: Currently the end line is consumed and does not form part of the
      # collected array.
      def partition_and_process_non_tabular_lines
        non_tabular_lines.each do |line|
          if line =~ row_mapping.start_line_pattern
            # This is a start line
            start_record(line)
          elsif line =~ row_mapping.end_line_pattern
            # This is an end line
            end_record
          else
            @non_tabular_record << line if @in_a_record
          end
        end
      end

      # Checks to see if we get the start of a new record before getting the end of the previous
      # one and fails if so. Otherwise it tabulates the previous record
      def start_record(line)
        if row_mapping.end_line_pattern
          fail UnifiedSources::Import::MappingError,
               I18n.t('mapping.errors.start_pattern_before_end') if @in_a_record
        else
          # No endline mapping
          @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        end
        @non_tabular_record = UnifiedSources::Import::NonTabular::Record.new
        @non_tabular_record << line if row_mapping.capture_start_line
        @in_a_record = true
      end

      # Tabulate the record (if in one), flagged it as no longer being in a record
      # and set the record to be a new one.
      def end_record
        @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        @in_a_record = false
        @non_tabular_record = UnifiedSources::Import::NonTabular::Record.new
      end

      # If the non-tabular data ends in a record (i.e. the last record is terminated by the EOF)
      # then we need to process the last record manually or flag those lines as not being part
      # of a record
      def process_end_of_record
        return if @non_tabular_record.empty?
        if row_mapping.end_in_a_record
          @tabular_array << @non_tabular_record.tabulate(column_mappings) if @in_a_record
        else
          @non_tabular_record.not_a_record!
        end
      end

      # Store the source lines as instances of UnifiedSources::Import::NonTabular::Line
      def non_tabular_lines=(lines)
        # TODO: replace with map with_index pattern in Ruby 2
        i = 0
        @non_tabular_lines = lines.map do |line|
          non_tabular_line = UnifiedSources::Import::NonTabular::Line.new(line)
          non_tabular_line.absolute_line_number = i
          i += 1
          non_tabular_line
        end
      end

      # Create and memoize the row mappings
      def row_mapping
        @row_mapping ||= UnifiedSources::Import::NonTabular::Mapping.new(@mappings)
      end

      # Create and memoize the column mappings
      def column_mappings
        @column_mappings ||= raw_column_mappings.map do |column_mapping|
          UnifiedSources::Import::NonTabular::ColumnMapping.new(column_mapping)
        end
      end

      def raw_column_mappings
        @mappings['columns'] || []
      end

      # This method compares two arrays, where the first must be an array of
      # UnifiedSources::Import::NonTabular::Line or string elements
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
