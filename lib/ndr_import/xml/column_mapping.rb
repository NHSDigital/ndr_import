module NdrImport
  module Xml
    # This class generates new XML column mappings where repeating columns/sections have been
    # identified in the xml.
    # This avoids the need for mappings to verbosly define repeating columns/sections
    class ColumnMapping
      INCREMENT_REGEX = /\[(\d+)\]/

      attr_accessor :existing_column, :unmapped_node_parts, :klass_increment, :xml_line, :klass,
                    :repeating_item, :increment_field_name, :build_new_record, :klass_section_xpath

      def initialize(existing_column, unmapped_node_parts, klass_increment, xml_line, klass)
        @existing_column      = existing_column
        @unmapped_node_parts  = unmapped_node_parts
        @klass_increment      = klass_increment
        @xml_line             = xml_line
        @klass                = klass

        xml_cell              = existing_column['xml_cell']
        @repeating_item       = xml_cell&.dig('multiple')
        @increment_field_name = xml_cell&.dig('increment_field_name')
        @build_new_record     = xml_cell&.dig('build_new_record')
        @klass_section_xpath  = xml_cell&.dig('klass_section')
        @existing_klass       = existing_column['klass']
        @klass_is_array       = @existing_klass.is_a?(Array)

        freeze
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
        if @klass_is_array
          @existing_klass.map { |column_klass| column_klass + "##{klass_increment}" }
        else
          @existing_klass + "##{klass_increment}"
        end
      end

      # Append "_1.1", "_2.1", "_1" etc to repeating rawtext and optionally mapped field names
      # within a single record, so data is not overwritten
      def apply_new_rawtext_and_mapped_names_to(new_column)
        increment_suffix = extract_increment_from_column(new_column)
        return unless increment_suffix

        apply_rawtext_increment(new_column, increment_suffix)
        apply_mappings_increment(new_column, increment_suffix) if increment_field_name
      end

      def extract_increment_from_column(new_column)
        column_increments   = new_column['column'].scan(INCREMENT_REGEX)
        path_increments     = new_column.dig('xml_cell', 'relative_path').scan(INCREMENT_REGEX)
        combined_increments = (column_increments + path_increments).join('.')

        combined_increments.presence
      end

      def apply_rawtext_increment(new_column, increment)
        existing_rawtext = existing_column['rawtext_name'] || existing_column['column']
        new_column['rawtext_name'] = "#{existing_rawtext}_#{increment}"
      end

      # Increment the mapped `field` names
      def apply_mappings_increment(new_column, increment)
        new_column['mappings'].map do |mapping|
          mapping['field'] = "#{mapping['field']}_#{increment}"

          mapping
        end
      end
    end
  end
end
