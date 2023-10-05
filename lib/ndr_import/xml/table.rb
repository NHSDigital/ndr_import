require 'ndr_import/table'

module NdrImport
  module Xml
    # This class maintains the state of a xml table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      XML_OPTIONS = %w[pattern_match_record_xpath xml_record_xpath yield_xml_record].freeze

      def self.all_valid_options
        super - %w[delimiter header_lines footer_lines] + XML_OPTIONS
      end

      attr_reader(*XML_OPTIONS)

      def header_lines
        0
      end

      def footer_lines
        0
      end

      # This method transforms an incoming line (element) of xml data by applying
      # each of the klass masked mappings to the line and yielding the klass
      # and fields for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?
        raise 'Not an Nokogiri::XML::Element!' unless line.is_a? Nokogiri::XML::Element

        augment_and_validate_column_mappings_for(line)

        xml_line = xml_line_from(line)
        records_from_xml_line = []

        masked_mappings.each do |klass, klass_mappings|
          fields = mapped_line(xml_line, klass_mappings)

          next if fields[:skip].to_s == 'true'.freeze

          if yield_xml_record
            records_from_xml_line << [klass, fields, index]
          else
            yield(klass, fields, index)
          end
        end
        yield(records_from_xml_line.compact) if yield_xml_record
      end

      private

      def xml_line_from(line)
        @column_xpaths.map do |column_xpath|
          # Augmenting the column mappings should account for repeating sections/items
          line.xpath(column_xpath).count > 1 ? '' : line.xpath(column_xpath).inner_text
        end
      end

      def augment_and_validate_column_mappings_for(line)
        augment_column_mappings_for(line)
        validate_column_mappings(line)
      end

      # Add missing column mappings where repeating sections / data items appear
      def augment_column_mappings_for(line)
        missing = unmapped_nodes(line)
        return if missing.none?

        missing.each do |unmapped_node|
          exsiting_column = find_existing_column_for(unmapped_node.dup)
          next unless exsiting_column

          unmapped_node_parts   = unmapped_node_parts(unmapped_node)
          klass_increment_match = unmapped_node.match(/\[(\d+)\]/)
          raise "could not identify klass for #{unmapped_node}" unless klass_increment_match

          new_column = new_column_mapping_for(exsiting_column, unmapped_node_parts,
                                              klass_increment_match[1])
          columns << new_column
          @column_xpaths << build_xpath_from(new_column)
        end
      end

      def find_existing_column_for(unmapped_node)
        # Remove any e.g. [2] which will be present on repeating sections
        unmapped_node.gsub!(/\[\d+\]/, '')
        unmapped_node_parts = unmapped_node_parts(unmapped_node)
        columns.detect do |column|
          column['column'] == unmapped_node_parts[:column_name] &&
            column.dig('xml_cell', 'relative_path') == unmapped_node_parts[:column_relative_path] &&
            column.dig('xml_cell', 'attribute') == unmapped_node_parts[:column_attribute]
        end
      end

      def unmapped_node_parts(unmapped_node)
        unmapped_node_parts       = unmapped_node.split('/')
        unmapped_column_attribute = new_column_attribute_from(unmapped_node_parts)

        { column_attribute: unmapped_column_attribute,
          column_name: new_column_name_from(unmapped_node_parts, unmapped_column_attribute),
          column_relative_path: new_relative_path_from(unmapped_node_parts,
                                                       unmapped_column_attribute) }
      end

      def new_column_mapping_for(exsiting_column, unmapped_node_parts, klass_increment)
        new_column = exsiting_column.deep_dup
        if exsiting_column.dig('xml_cell', 'multiple')
          new_column['rawtext_name'] = exsiting_column['rawtext_name'] + "_#{klass_increment}"
        end
        new_column['column'] = unmapped_node_parts[:column_name]
        new_column['xml_cell']['relative_path'] = unmapped_node_parts[:column_relative_path]
        new_column['klass'] = exsiting_column['klass'] + "##{klass_increment}" unless @klass

        new_column
      end

      def new_column_attribute_from(unmapped_node_parts)
        unmapped_node_parts.last.starts_with?('@') ? unmapped_node_parts.last[1...] : nil
      end

      def new_column_name_from(unmapped_node_parts, unmapped_column_attribute)
        unmapped_column_attribute.present? ? unmapped_node_parts[-2] : unmapped_node_parts.last
      end

      def new_relative_path_from(unmapped_node_parts, unmapped_column_attribute)
        upper_limit = unmapped_column_attribute.present? ? -3 : -2
        unmapped_node_parts.count > 1 ? unmapped_node_parts[0..upper_limit].join('/') : nil
      end

      # Ensure every leaf is accounted for in the column mappings
      def validate_column_mappings(line)
        missing_nodes = unmapped_nodes(line)
        raise "Unmapped data! #{missing_nodes}" unless missing_nodes.empty?
      end

      # Not memoized this by design, we want to re-calculate unmapped nodes after
      # `columns` have been augmented for each `line`
      def unmapped_nodes(line)
        mappable_xpaths_from(line) - column_xpaths
      end

      def column_name_from(column)
        column[Strings::COLUMN] || column[Strings::STANDARD_MAPPING]
      end

      def column_xpaths
        @column_xpaths ||= columns.map { |column| build_xpath_from(column) }
      end

      def mappable_xpaths_from(line)
        xpaths = []

        line.xpath('.//*[not(child::*)]').each do |node|
          xpath = node.path.sub("#{line.path}/", '')
          if node.attributes.any?
            node.attributes.each_key { |key| xpaths << "#{xpath}/@#{key}" }
          else
            xpaths << xpath
          end
        end
        xpaths
      end

      def build_xpath_from(column)
        column_name = column_name_from(column)
        column['xml_cell'].presence ? relative_path_from(column, column_name) : column_name
      end

      def relative_path_from(column, colum_name)
        xml_cell      = column['xml_cell']
        relative_path = xml_cell['relative_path'].presence ? xml_cell['relative_path'] : nil
        attribute     = xml_cell['attribute'].presence ? '@' + xml_cell['attribute'] : nil

        if relative_path && attribute
          relative_path + '/' + colum_name + '/' + attribute
        elsif relative_path
          relative_path + '/' + colum_name
        elsif attribute
          colum_name + '/' + attribute
        else
          colum_name
        end
      end

      # Not memoizing this by design, @columns can change if new column mappings are
      # added on thw fly
      def masked_mappings
        if @klass
          { @klass => @columns }
        else
          column_level_klass_masked_mappings
        end
      end
    end
  end
end
