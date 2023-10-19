require 'ndr_import/table'

module NdrImport
  module Xml
    # This class maintains the state of a xml table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      require 'ndr_import/xml/column_mapping'
      require 'ndr_import/xml/masked_mappings'

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

        augmented_masked_mappings = augment_and_validate_column_mappings_for(line)

        xml_line = xml_line_from(line)

        records_from_xml_line = []
        augmented_masked_mappings.each do |klass, klass_mappings|
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

      def augment_and_validate_column_mappings_for(line)
        augment_column_mappings_for(line)
        validate_column_mappings(line)

        NdrImport::Xml::MaskedMappings.new(@klass, @augmented_columns.deep_dup).call
      end

      # Add missing column mappings (and column_xpaths) where
      # repeating sections / data items appear
      def augment_column_mappings_for(line)
        # Start with a fresh set of @augmented_columns for each line, adding new mappings as
        # required for each `line`
        @augmented_columns       = @columns.deep_dup
        @augmented_column_xpaths = column_xpaths.deep_dup

        unmapped_xpaths(line).each do |unmapped_xpath|
          existing_column = find_existing_column_for(unmapped_xpath.dup)
          next unless existing_column

          unmapped_xpath_hash   = labelled_xpath_components_from(unmapped_xpath)
          klass_increment_match = unmapped_xpath.match(/\[(\d+)\]/)
          raise "could not identify klass for #{unmapped_xpath}" unless klass_increment_match

          new_column = NdrImport::Xml::ColumnMapping.new(existing_column, unmapped_xpath_hash,
                                                         klass_increment_match[1], line,
                                                         @klass).call
          @augmented_columns << new_column
          @augmented_column_xpaths << build_xpath_from(new_column)
        end
      end

      def xml_line_from(line)
        @augmented_column_xpaths.map do |column_xpath|
          # Augmenting the column mappings should account for repeating sections/items
          # TODO: Is this needed now that we removed "duplicated" klass mappings?
          line.xpath(column_xpath).count > 1 ? '' : line.xpath(column_xpath).inner_text
        end
      end

      def find_existing_column_for(unmapped_xpath)
        # Remove any e.g. [2] which will be present on repeating sections
        unmapped_xpath.gsub!(/\[\d+\]/, '')
        unmapped_xpath_hash = labelled_xpath_components_from(unmapped_xpath)
        columns.detect do |column|
          column['column'] == unmapped_xpath_hash[:column_name] &&
            column.dig('xml_cell', 'relative_path') == unmapped_xpath_hash[:column_relative_path] &&
            column.dig('xml_cell', 'attribute') == unmapped_xpath_hash[:column_attribute]
        end
      end

      # Returns a Hash containing labelled components for the given `unmapped_xpath`
      # For example, an `unmapped_xpath` of "Record/Demographics/Sex/@code" would result in:
      # { column_attribute: '@code',
      #   column_name: 'Sex',
      #   column_relative_path: 'Record/Demographics' }
      def labelled_xpath_components_from(unmapped_xpath)
        xpath_components = unmapped_xpath.split('/')
        column_attribute = new_column_attribute_from(xpath_components)

        { column_attribute: column_attribute,
          column_name: new_column_name_from(xpath_components, column_attribute),
          column_relative_path: new_relative_path_from(xpath_components, column_attribute) }
      end

      def new_column_attribute_from(xpath_components)
        xpath_components.last.starts_with?('@') ? xpath_components.last[1...] : nil
      end

      def new_column_name_from(xpath_components, column_attribute)
        return xpath_components[-2] if column_attribute.present?

        xpath_components.last
      end

      # xpaths can be e.g. Record/Demographics/Sex/@code or Record/Demographics/Surname
      # `xpath_components` is an array of the xpath's components, for example:
      # Record/Demographics/Sex/@code => ['Record', 'Demographics', 'Sex', '@code']
      #
      # For the relative path, we want to return Record/Demographics.
      # The upper_limit removes the "field name" (Sex or Surname here) and optionally the
      # attribute (@code here) if present, from `xpath_components`.
      # The resulting array is joined back together to form the relative path.
      def new_relative_path_from(xpath_components, column_attribute)
        upper_limit = column_attribute.present? ? -3 : -2
        xpath_components.count > 1 ? xpath_components[0..upper_limit].join('/') : nil
      end

      # Ensure every leaf is accounted for in the column mappings
      def validate_column_mappings(line)
        missing_xpaths = unmapped_xpaths(line)
        raise "Unmapped data! #{missing_xpaths}" unless missing_xpaths.empty?
      end

      # Not memoized this by design, we want to re-calculate unmapped xpaths after
      # `@augmented_column_xpaths` have been augmented for each `line`
      def unmapped_xpaths(line)
        mappable_xpaths_from(line) - (@augmented_column_xpaths || column_xpaths)
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
    end
  end
end
