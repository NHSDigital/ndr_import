module NdrImport
  module Xml
    # This class generates new XML column mappings where repeating columns/sections have been
    # identified in the xml.
    # This avoids need to need for mappings to verbosly define repeating columns/sections
    class ColumnMapping
      attr_accessor :existing_column, :unmapped_node_parts, :klass_increment, :xml_line, :klass

      def initialize(existing_column, unmapped_node_parts, klass_increment, xml_line, klass)
        @existing_column     = existing_column
        @unmapped_node_parts = unmapped_node_parts
        @klass_increment     = klass_increment
        @xml_line            = xml_line
        @klass               = klass
      end

      def call
        new_column                              = existing_column.deep_dup
        new_column['column']                    = unmapped_node_parts[:column_name]
        new_column['xml_cell']['relative_path'] = unmapped_node_parts[:column_relative_path]

        repeating_item = existing_column.dig('xml_cell', 'multiple')

        # create unique rawtext names for repeating sections within a record
        apply_new_rawtext_and_mapped_names_to(new_column) if repeating_item

        return new_column if new_record_not_needed?(repeating_item)

        new_column['klass'] = incremented_klass
        new_column
      end

      private

      # If a table level klass is defined, there is nothing to increment at the column level.
      # Similarly, not all repeating sections/items require a separate record.
      # No need to create new records for a single occurence of a repeating section
      def new_record_not_needed?(repeating_item)
        section_xpath    = existing_column.dig('xml_cell', 'section')
        build_new_record = existing_column.dig('xml_cell', 'build_new_record')

        klass.present? || build_new_record == false ||
          (repeating_item && xml_line.xpath(section_xpath).one?)
      end

      def incremented_klass
        if existing_column['klass'].is_a?(Array)
          existing_column['klass'].map do |column_klass|
            column_klass + "##{klass_increment}"
          end
        else
          existing_column['klass'] + "##{klass_increment}"
        end
      end

      # Append "_1", "_2" etc to repeating rawtext and optionally mapped field names within a
      # single record, so data is not overwritten
      def apply_new_rawtext_and_mapped_names_to(new_column)
        existing_rawtext        = existing_column['rawtext_name'] || existing_column['column']
        column_name_increment   = new_column['column'].match(/\[(\d+)\]\z/)
        relative_path_increment = new_column.dig('xml_cell', 'relative_path').match(/\[(\d+)\]\z/)

        increment = column_name_increment || relative_path_increment
        new_column['rawtext_name'] = existing_rawtext + "_#{increment[1]}" if increment

        return unless increment && new_column.dig('xml_cell', 'increment_field_name')

        mappings = new_column['mappings'].map do |mapping|
          mapping['field'] = "#{mapping['field']}_#{increment[1]}"

          mapping
        end

        new_column['mappings'] = mappings
      end
    end
  end
end
