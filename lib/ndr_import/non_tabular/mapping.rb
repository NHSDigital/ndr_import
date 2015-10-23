# encoding: UTF-8
require 'ndr_import/non_tabular/table'

module NdrImport
  module NonTabular
    # This class stores the mapping used to break an incoming file into multiple rows/records
    class Mapping < Table
      def self.all_valid_options
        super + %w(non_tabular_row)
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

      private

      def initialize_non_tabular_mappings(non_tabular_mappings)
        NON_TABULAR_OPTIONS.each do |key|
          next unless non_tabular_mappings[key]
          instance_variable_set("@#{key}", non_tabular_mappings[key])
        end
      end
    end
  end
end
