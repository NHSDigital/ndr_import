# encoding: UTF-8

module NdrImport
  module NonTabular
    # This class stores the mapping used to break an incoming file into multiple rows/records
    class Mapping
      attr_accessor :capture_start_line, :start_line_pattern, :end_line_pattern,
                    :start_in_a_record, :end_in_a_record, :remove_lines

      def initialize(mappings)
        @non_tabular_mappings = mappings['non_tabular_row']

        validate_row_mapping

        @capture_start_line = @non_tabular_mappings['capture_start_line']
        @start_line_pattern = @non_tabular_mappings['start_line_pattern']
        @end_line_pattern   = @non_tabular_mappings['end_line_pattern']
        @start_in_a_record  = @non_tabular_mappings['start_in_a_record'] || false
        @end_in_a_record    = @non_tabular_mappings['end_in_a_record']
        @remove_lines       = @non_tabular_mappings['remove_lines']
      end

      def validate_row_mapping
        validate_presence_of_non_tabular_row
        validate_presence_of_non_tabular_row_start_line_pattern
      end

      def validate_presence_of_non_tabular_row
        return if @non_tabular_mappings
        fail NdrImport::MappingError,
             I18n.t('mapping.errors.missing_non_tabular_row')
      end

      def validate_presence_of_non_tabular_row_start_line_pattern
        return if @non_tabular_mappings['start_line_pattern']
        fail NdrImport::MappingError,
             I18n.t('mapping.errors.missing_start_line_pattern')
      end
    end
  end
end
