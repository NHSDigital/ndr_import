require 'ndr_import/file/registry'

module NdrImport
  # This mixin provides file importer helper methods that abstract away some of the
  # complexity of enumerating over files and tables (which should be universally useful).
  module UniversalImporterHelper
    def table_enumerators(filename)
      table_enumerators = {}

      extract(filename).each do |table, rows|
        table_enumerators[table.canonical_name] = table.transform(rows)
      end

      table_enumerators
    end

    # This method returns the correct NdrImport::{,NonTabular::}Table for the given
    # filename/tablename. It requires all the mappings to be stored in the table_mappings
    # instance variable.
    def get_table_mapping(filename, tablename)
      @table_mappings.find { |mapping| mapping.match(filename, tablename) }
    end

    # Iterate through the file(s) line by line, yielding each one in turn, using
    # get_table_mapping to select the mapping relevant to this file.
    def extract(source_file, unzip_path, &block)
      return enum_for(:extract, source_file, unzip_path) unless block

      files = NdrImport::File::Registry.files(source_file,
                                              'unzip_path' => unzip_path)
      files.each do |filename|
        # now at the individual file level, can we find the table mapping?
        table_mapping = get_table_mapping(filename, nil)

        tables = NdrImport::File::Registry.tables(filename,
                                                  table_mapping.try(:format),
                                                  'unzip_path' => unzip_path,
                                                  'col_sep'    => table_mapping.try(:delimiter),
                                                  'root_node'  => table_mapping.try(:root_node))
        yield_tables_and_their_content(filename, tables, &block)
      end
    end

    # This method does the table row yielding for the extract method, setting the notifier
    # so that we can monitor progress
    def yield_tables_and_their_content(filename, tables, &block)
      tables.each do |tablename, table_content|
        mapping = get_table_mapping(filename, tablename)
        next if mapping.nil?

        total_records = table_content.count unless table_content.is_a?(Enumerator)
        mapping.notifier = get_notifier(total_records)

        yield(mapping, table_content)
      end
    end

    # This method needs to be implemented where this mixin is used.
    def get_notifier(_total_records)
      fail 'Implement get_notifier'
    end
  end
end
