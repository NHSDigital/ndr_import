# encoding: UTF-8
require 'ndr_import/non_tabular/table'

module NdrImport
  module NonTabular
    # This class stores the mapping used to break an incoming file into multiple rows/records
    class Mapping < Table
      def self.all_valid_options
        super - %w(header_lines footer_lines) + %w(non_tabular_row)
      end

      def initialize(options)
        non_tabular_mappings = options['non_tabular_row']
        if non_tabular_mappings
          initialize_non_tabular_mappings(non_tabular_mappings)
        else
          # validate presence of non_tabular_row
          fail NdrImport::MappingError,
               I18n.t('mapping.errors.missing_non_tabular_row')
        end

        super(options)
      end

      def start_in_a_record
        @header_lines == 0
      end

      def end_in_a_record
        @footer_lines == 0
      end

      private

      def initialize_non_tabular_mappings(non_tabular_mappings)
        NON_TABULAR_OPTIONS.each do |key|
          next unless non_tabular_mappings[key]
          instance_variable_set("@#{key}", non_tabular_mappings[key])
        end

        @header_lines = non_tabular_mappings['start_in_a_record'] ? 0 : 1
        @footer_lines = non_tabular_mappings['end_in_a_record'] ? 0 : 1
      end
    end
  end
end
