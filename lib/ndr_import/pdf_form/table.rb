require 'ndr_import/table'

module NdrImport
  module PdfForm
    # This class maintains the state of a PDF form table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      def self.all_valid_options
        super - %w[delimiter footer_lines format header_lines]
      end

      def footer_lines
        0
      end

      def format
        'acroform'
      end

      def header_lines
        0
      end

      # This method transforms an incoming line (Hash) of data.
      # Each of the klass masked mappings are applied to the hash values, which are reordered by
      # the mappng definition, yielding the klass and fields for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?

        raise 'NdrImport::PdfForm::Table expects a Hash!' unless line.is_a? Hash

        validate_column_mappings(line)

        masked_mappings.each do |klass, klass_mappings|
          ordered_line = order_values_by_mappings(line, klass_mappings)
          fields       = mapped_line(ordered_line, klass_mappings)
          next if fields[:skip].to_s == 'true'.freeze
          yield(klass, fields, index)
        end
      end

      private

      # Ensure every key has a column mapping
      def validate_column_mappings(line)
        unmapped = []
        line.each_key do |key|
          next if column_names.include? key
          unmapped << key
        end
        raise NdrImport::UnmappedDataError, unmapped if unmapped.any?
      end

      def column_name_from(column)
        column[Strings::COLUMN] || column[Strings::STANDARD_MAPPING]
      end

      def column_names
        @column_names ||= columns.map { |column| column_name_from(column) }
      end

      # Return an Array of the `hash` values in the order the columns are defined in the mapping,
      # allowing mapped_line to work as normal
      def order_values_by_mappings(hash, column_mappings)
        column_mappings.map { |column_mapping| hash[column_name_from(column_mapping)].to_s }
      end
    end
  end
end
