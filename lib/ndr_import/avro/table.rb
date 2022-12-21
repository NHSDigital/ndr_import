require 'ndr_import/table'

module NdrImport
  module Avro
    # This class maintains the state of an avro table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      def self.all_valid_options
        super - %w[delimiter header_lines footer_lines]
      end

      def header_lines
        0
      end

      def footer_lines
        0
      end

      # This method transforms an incoming line (Hash) of avro data by applying
      # each of the klass masked mappings to the line and yielding the klass,
      # fields and index for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?

        raise 'Not a Hash!' unless line.is_a? Hash

        line.transform_keys!(&:downcase)

        missing      = lower_case_column_names - line.keys
        unexpected   = line.keys - lower_case_column_names
        raise "Missing columns: #{missing.to_sentence}"       if missing.any?
        raise "Unexpected columns: #{unexpected.to_sentence}" if unexpected.any?

        # Ensure the `avro_line` is in the same order as the column mappings
        # TODO: Do we need to do this, can we just assume column order?
        # TODO: Should we call `to_s` on the value here? Rawtext data is typically stored in
        #       strings, not Date objects, etc
        avro_line = lower_case_column_names.map { |column_name| line[column_name]&.to_s }

        masked_mappings.each do |klass, klass_mappings|
          fields = mapped_line(avro_line, klass_mappings)
          next if fields[:skip].to_s == 'true'.freeze

          yield(klass, fields, index)
        end
      end

      private

      def lower_case_column_names
        @lower_case_column_names ||= column_names(@columns).map(&:downcase)
      end
    end
  end
end
