require 'ndr_import/table'

module NdrImport
  module Avro
    # Syntatic sugar to ensure `header_lines` and `footer_lines` are 1 and 0 respectively.
    # All other Table logic is inherited from `NdrImport::Table`
    class Table < ::NdrImport::Table
      # Scaffold an `NdrImport::Avro::Table` instance from avro schema file
      def self.from_schema(safe_path)
        raise SecurityError, "#{safe_path} is not a SafePath" unless safe_path.is_a? SafePath

        schema_hash   = JSON.load_file(safe_path)
        table_columns = schema_hash['fields'].map { |field| { column: field['name'] } }
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
    end
  end
end
