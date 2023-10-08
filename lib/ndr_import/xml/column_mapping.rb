# encoding: UTF-8

module NdrImport
  module Xml
    # This class generates new XML column mappings where repeating columns/sections have been
    # identifued in the xml.
    # This avoids need to need for mappings verbosly defining repeating columns/sections
    class ColumnMapping
      attr_accessor :existing_column, :unmapped_node_parts, :klass_increment, :xml_line

      def initialize(existing_column, unmapped_node_parts, klass_increment, xml_line)
        @existing_column     = existing_column
        @unmapped_node_parts = unmapped_node_parts
        @klass_increment     = klass_increment
        @xml_line            = xml_line
      end

      def call
        new_column                              = existing_column.deep_dup
        new_column['column']                    = unmapped_node_parts[:column_name]
        new_column['xml_cell']['relative_path'] = unmapped_node_parts[:column_relative_path]

        repeating_item   = existing_column.dig('xml_cell', 'multiple')
        section_xpath    = existing_column.dig('xml_cell', 'section')
        build_new_record = existing_column.dig('xml_cell', 'build_new_record')

        # create unique rawtext names for repeating sections within a record
        new_column['rawtext_name'] = new_rawtext_name(new_column) if repeating_item

        # If a table level @klass is defined, there is nothing to increment at the column level.
        # Similarly, not all repeating sections/items require a separate record.
        # No need to create new records for a single occurence of a repeating section
        no_new_record = @klass.present? || build_new_record == false ||
                        (repeating_item && xml_line.xpath(section_xpath).one?)
        new_column['klass'] = existing_column['klass'] + "##{klass_increment}" unless no_new_record

        new_column
      end

      private

      # append "_1", "_2" etc to repeating rawtext names within a single record
      def new_rawtext_name(new_column)
        existing_rawtext       = existing_column['rawtext_name'] || existing_column['column']
        column_name_increment  = new_column['column'].match(/\[(\d+)\]\z/)
        relative_pathincrement = new_column.dig('xml_cell', 'relative_path').match(/\[(\d+)\]\z/)

        rawtext_increment = column_name_increment || relative_pathincrement
        rawtext_increment ? existing_rawtext + "_#{rawtext_increment[1]}" : existing_rawtext
      end
    end
  end
end
