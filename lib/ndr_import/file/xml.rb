require 'ndr_support/safe_file'
require 'ndr_import/helpers/file/xml'
require 'ndr_import/helpers/file/xml_streaming'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a xml file handler that returns a single table.
    class Xml < Base
      include NdrImport::Helpers::File::Xml
      include NdrImport::Helpers::File::XmlStreaming

      def initialize(*)
        super

        @pattern_match_xpath = @options['pattern_match_record_xpath']
        @xml_file_metadata   = @options['xml_file_metadata']
        @options['slurp'] ? prepare_slurped_file : prepare_streamed_file
      end

      private

      def prepare_slurped_file
        @doc = read_xml_file(@filename)
        slurp_metadata_values
      end

      def prepare_streamed_file
        with_encoding_check(@filename) do |stream, encoding|
          @stream   = stream
          @encosing = encoding
        end
        stream_metadata_values
      end

      def slurp_metadata_values
        return unless @xml_file_metadata.is_a?(Hash)

        self.file_metadata = @xml_file_metadata.transform_values do |xpath|
          @doc.xpath(xpath).inner_text
        end
      end

      def stream_metadata_values
        return unless @xml_file_metadata.is_a?(Hash)

        self.file_metadata = @xml_file_metadata.transform_values.with_index do |xpath, index|
          # Ensure we're at the start of the stream each time
          @stream.rewind unless index.zero?

          metadata_from_stream(xpath)
        end
      end

      def metadata_from_stream(xpath)
        cursor = Cursor.new(xpath, false)

        # If markup isn't well-formed, try to work around it:
        options = Nokogiri::XML::ParseOptions::RECOVER
        reader  = Nokogiri::XML::Reader(@stream, nil, @encoding, options)

        reader.each do |node|
          case node.node_type
          when Nokogiri::XML::Reader::TYPE_ELEMENT # "opening tag"
            raise NestingError, node if cursor.in?(node)

            cursor.enter(node)
            return cursor.inner_text if cursor.send(:current_stack_match?)
          when Nokogiri::XML::Reader::TYPE_END_ELEMENT # "closing tag"
            cursor.leave(node)
          end
        end
      end

      # Iterate through the file, yielding each 'xml_record_xpath' element in turn.
      def rows(&block)
        return enum_for(:rows) unless block

        if @options['slurp']
          record_elements.each(&block)
        else
          @stream.rewind
          each_node(@stream, @encoding, xml_record_xpath, @pattern_match_xpath, &block)
        end
      end

      def xml_record_xpath
        @pattern_match_xpath ? @options['xml_record_xpath'] : "*/#{@options['xml_record_xpath']}"
      end

      def record_elements
        if @pattern_match_xpath
          @doc.root.children.find_all do |element|
            element.name =~ Regexp.new(@options['xml_record_xpath'])
          end
        else
          @doc.root.xpath(@options['xml_record_xpath'])
        end
      end
    end
    # Not all xml files may want to be registered, so 'xml' is not registered by design.
    Registry.register(Xml, 'xml_table')
  end
end
