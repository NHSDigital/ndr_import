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
        1
      end

      def footer_lines
        0
      end

      # This method transforms an incoming line (Hash) of avro data by applying
      # each of the klass masked mappings to the line and yielding the klass,
      # fields and index for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?

        # The first line will always be the "header"
        validate_header(line) if index.zero?

        masked_mappings.each do |klass, klass_mappings|
          fields = mapped_line(line.values.map(&:to_s), klass_mappings)
          next if fields[:skip].to_s == 'true'.freeze

          yield(klass, fields, index)
        end
      end

      private

      def validate_header(line)
        consume_header_line(line, @columns)
        fail_unless_header_complete(@columns) unless @header_valid
      end
    end
  end
end
