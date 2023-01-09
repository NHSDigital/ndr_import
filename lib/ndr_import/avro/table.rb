require 'ndr_import/table'

module NdrImport
  module Avro
    # Syntatic sugar to ensure `header_lines` and `footer_lines` are 1 and 0 respectively.
    # All other Table logic is inherited from `NdrImport::Table`
    class Table < ::NdrImport::Table
      # Scaffold an `NdrImport::Avro::Table` instance from avro schema file
      def self.from_schema(safe_path)
        raise SecurityError, "#{safe_path} is not a SafePath" unless safe_path.is_a? SafePath

        table_columns = columns_from(::Avro::Schema.parse(::File.open(safe_path)))
        file_name     = SafeFile.basename(safe_path).sub(/\.avsc\z/, '.avro')

        new(filename_pattern: "/#{file_name}\\z/",
            klass: 'ExampleKlass',
            columns: table_columns)
      end

      def self.all_valid_options
        super - %w[delimiter header_lines footer_lines]
      end

      def header_lines
        1
      end

      def footer_lines
        0
      end

      def self.columns_from(schema)
        schema.fields.map do |field|
          column = { column: field.name }
          column[:mappings] = { field: field.name, daysafter: '1970-01-01' } if date_field?(field)

          column
        end
      end

      def self.date_field?(field)
        field.type.schemas.any? { |schema| schema.logical_type == 'date' }
      end

      private_class_method :columns_from
      private_class_method :date_field?
    end
  end
end
