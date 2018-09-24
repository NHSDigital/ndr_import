require 'ndr_import/table'

module NdrImport
  module Xml
    # This class maintains the state of a xml table mapping and encapsulates
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

      # This method transforms an incoming line (element) of xml data by applying
      # each of the klass masked mappings to the line and yielding the klass
      # and fields for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?

        raise 'Not an Nokogiri::XML::Element!' unless line.is_a? Nokogiri::XML::Element

        validate_column_mappings(line)

        xml_line = column_xpaths.map { |column_xpath| line.xpath(column_xpath).inner_text }

        masked_mappings.each do |klass, klass_mappings|
          fields = mapped_line(xml_line, klass_mappings)
          next if fields[:skip].to_s == 'true'.freeze
          yield(klass, fields, index)
        end
      end

      private

      # Ensure every leaf is accounted for in the column mappings
      def validate_column_mappings(line)
        column_names  = columns.map { |column| column_name_from(column) }
        data_leaves   = line.xpath('//*[not(child::*)]').map(&:name)
        missing_nodes = data_leaves - column_names
        raise "Unmapped data! #{missing_nodes}" unless missing_nodes.empty?
      end

      def column_name_from(column)
        column[Strings::COLUMN] || column[Strings::STANDARD_MAPPING]
      end

      def column_xpaths
        @column_xpaths ||= columns.map { |column| build_xpath_from(column) }
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
    end
  end
end
