# encoding: UTF-8

module UnifiedSources
  module Import
    module NonTabular
      # This class stores the mapping for an individual non-tabular column, encapsulating
      # the logic associated with finding matching lines of source data and subsequently
      # capturing arrays of values within them.
      class ColumnMapping
        attr_accessor :name, :cell_mapping, :lines, :capture, :join

        def initialize(column_mapping)
          @name         = column_mapping['rawtext_name'] ||
                          column_mapping['column'] ||
                          column_mapping['standard_mapping']
          @cell_mapping = column_mapping['non_tabular_cell']

          validate_cell_mapping

          @lines = @cell_mapping['lines']
          @join  = @cell_mapping['join']
        end

        # This method returns the range of matching source data lines. If the range is a
        # RegexpRange then it will calculate it for the text provided.
        def matching_lines(text)
          if @lines.is_a?(RegexpRange)
            @lines.to_range(text)
          else
            @lines
          end
        end

        # capture the required part of the line by replacing (recusively) the line,
        # with the first captured regular expression group. This is hardcoded in an attempt
        # to preserve the rawtext as much as possible
        def capture_value(line)
          value = line.dup
          [@cell_mapping['capture']].flatten.each do |pattern|
            if matchdata = value.to_s.match(pattern)
              value = matchdata[1]
            else
              value = nil
            end
          end
          value
        end

        def validate_cell_mapping
          validate_presence_of_non_tabular_cell
          validate_presence_of_non_tabular_cell_lines
          validate_presence_of_non_tabular_cell_capture
        end

        def validate_presence_of_non_tabular_cell
          return if @cell_mapping
          fail UnifiedSources::Import::MappingError,
               I18n.t('mapping.errors.missing_non_tabular_cell', :name => @name)
        end

        def validate_presence_of_non_tabular_cell_lines
          return if @cell_mapping['lines']
          fail UnifiedSources::Import::MappingError,
               I18n.t('mapping.errors.missing_non_tabular_cell_lines', :name => @name)
        end

        def validate_presence_of_non_tabular_cell_capture
          return if @cell_mapping['capture']
          fail UnifiedSources::Import::MappingError,
               I18n.t('mapping.errors.missing_non_tabular_cell_capture', :name => @name)
        end
      end
    end
  end
end
