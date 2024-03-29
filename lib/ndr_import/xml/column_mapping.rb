module NdrImport
  module Xml
    # This class generates new XML column mappings where repeating columns/sections have been
    # identified in the xml.
    # This avoids the need for mappings to verbosly define repeating columns/sections
    class ColumnMapping
      attr_accessor :existing_column, :unmapped_node_parts, :klass_increment, :xml_line, :klass,
                    :repeating_item, :increment_field_name, :build_new_record, :klass_section_xpath

      def initialize(existing_column, unmapped_node_parts, klass_increment, xml_line, klass)
        @existing_column      = existing_column
        @unmapped_node_parts  = unmapped_node_parts
        @klass_increment      = klass_increment
        @xml_line             = xml_line
        @klass                = klass
        @repeating_item       = existing_column.dig('xml_cell', 'multiple')
        @increment_field_name = existing_column.dig('xml_cell', 'increment_field_name')
        @build_new_record     = existing_column.dig('xml_cell', 'build_new_record')
        @klass_section_xpath  = existing_column.dig('xml_cell', 'klass_section')
      end

      def call
        new_column                              = existing_column.deep_dup
        new_column['column']                    = unmapped_node_parts[:column_name]
        new_column['xml_cell']['relative_path'] = unmapped_node_parts[:column_relative_path]

        # create unique rawtext names for repeating sections within a record
        apply_new_rawtext_and_mapped_names_to(new_column) if repeating_item

        return new_column unless incremented_klass_needed?

        new_column['klass'] = incremented_klass
        new_column
      end

      private

      # If a table level klass is defined, there is nothing to increment at the column level.
      # Similarly, not all repeating sections/items require a separate record.
      # No need to create new records for a single occurence of a repeating section
      def incremented_klass_needed?
        return false if klass.present?
        # Column mapping needs to explicitly flag when additionals should not be made
        return false if build_new_record == false
        return false if xml_line.xpath(klass_section_xpath).one? && repeating_item

        true
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

      # Append "_1.1", "_2.1", "_1" etc to repeating rawtext and optionally mapped field names
      # within a single record, so data is not overwritten
      def apply_new_rawtext_and_mapped_names_to(new_column)
        existing_rawtext        = existing_column['rawtext_name'] || existing_column['column']
        column_name_increment   = new_column['column'].scan(/\[(\d+)\]/)
        relative_path_increment = new_column.dig('xml_cell', 'relative_path').scan(/\[(\d+)\]/)

        # Find all the increments (e.g. [1], [2]) from the new column and concatenate them to
        # use as the rawtext and column name increment
        increment = (column_name_increment + relative_path_increment).flatten.compact.join('.')
        new_column['rawtext_name'] = existing_rawtext + "_#{increment}" if increment.present?

        return unless increment.present? && increment_field_name

        new_column['mappings'] = incremented_mappings_for(new_column, increment)
      end

      # Increment the mapped `field` names
      def incremented_mappings_for(new_column, increment)
        new_column['mappings'].map do |mapping|
          mapping['field'] = "#{mapping['field']}_#{increment}"

          mapping
        end
      end
    end
  end
end
