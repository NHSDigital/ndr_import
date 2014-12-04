# encoding: UTF-8

module UnifiedSources
  module Import
    module NonTabular
      # This class behaves like an array of UnifiedSources::Import::NonTabular::Line elements
      # that contains all the source lines of text that relate to a single record of data.
      # It also encapsulates the logic that tabulates the data.
      class Record
        attr_reader :lines

        def initialize
          @lines = []
        end

        def <<(line)
          return if line.removed
          line.in_a_record = true
          line.record_line_number = @lines.length
          @lines << line
        end

        def empty?
          @lines.empty?
        end

        # Call this if it turns out that this is not a record.
        # All lines will be flagged accordingly.
        def not_a_record!
          @lines.each { |line| line.in_a_record = false }
        end

        # Returns an array of "cells" for a given array of lines of a file that represent
        # a single "row" of data. Allowing the output to be mapped by the standard mapper.
        #
        # ==== Signature
        #
        #   tabulate(mappings)
        #
        # ==== Examples
        #
        #   If the YAML mapping is
        #   ---
        #   - standard_mapping: nhsnumber
        #     non_tabular_cell:
        #       lines: 0
        #       capture:
        #       - !ruby/regexp /^D\|([^|]*).*/
        #   - column: fulltextreport
        #     non_tabular_cell:
        #       lines: !ruby/range
        #         begin: 1
        #         end: -1
        #         excl: false
        #       capture: !ruby/regexp /^(?:R|\d+)\|(.*)$/i
        #       join: \n
        #
        #   lines = [
        #     "D|1111111111|...",
        #     "R|This is a",
        #     "1|multiline report"
        #   ]
        #
        #   tabulate(mappings)
        #
        #   # =>
        #   [
        #     "1111111111",
        #     "This is a\nmultiline report"
        #   ]
        #
        def tabulate(mappings)
          cells = []
          mappings.each do |column_mapping|
            begin
              matches = get_matches(column_mapping)
              # Join the non-blank lines together and add to the array of cells
              cells << matches.select { |value| !value.blank? }.join(column_mapping.join || '')
            rescue RegexpRange::PatternMatchError
              cells << nil
            end
          end
          cells
        end

        # returns an array of matches from within the captured lines
        def get_matches(column_mapping)
          matching_lines = column_mapping.matching_lines(@lines)
          # loop through the specified line (or lines)
          matches = [@lines[matching_lines]].flatten.map do |line|
            line.captured_for(column_mapping.name)
            value = column_mapping.capture_value(line)
            line.matches_for(column_mapping.name, value)
            value
          end
          matches
        end
      end
    end
  end
end
