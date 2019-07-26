require 'test_helper'
require 'ndr_import/helpers/file/xml_streaming'
require 'nokogiri'

# XML streaming file helper tests
class XmlStreamingTest < ActiveSupport::TestCase
  # This is a test importer class to test the XML streaming file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::XmlStreaming

    def initialize(safe_path)
      @safe_path = safe_path
    end

    def nodes(xpath, xml)
      file_name = 'streaming_test.xml'
      file_path = @safe_path.join(file_name)
      SafeFile.open(file_path, 'w') { |f| f.write xml }

      nodes_from_file(xpath, file_name)
    ensure
      SafeFile.delete(file_path)
    end

    def nodes_from_file(xpath, file_name)
      file_path = @safe_path.join(file_name)
      [].tap do |nodes|
        stream_xml_nodes(file_path, xpath) { |node| nodes << node }
      end
    end
  end

  def setup
    @importer = TestImporter.new SafePath.new('permanent_test_files')
  end

  test 'should yield matching nodes' do
    assert_equal 2, @importer.nodes('//node', <<~XML).length
      <nodes><node></node><node></node></nodes>
    XML
  end

  test 'should guard against nesting limitation' do
    exception = assert_raises(NdrImport::Helpers::File::XmlStreaming::NestingError) do
      @importer.nodes('//node', <<~XML).length
        <nodes><node><node></node></node></nodes>
      XML
    end

    assert_match(/Element 'node' was found/, exception.message)
    assert_match(/known limitation of XmlStreaming/, exception.message)
  end

  test 'should be able to find the root node' do
    assert_equal 1, @importer.nodes('/*', <<~XML).length
      <nodes><node></node><node></node></nodes>
    XML
  end

  test 'should yield matching nodes with attributes' do
    assert_equal 1, @importer.nodes('//nodes[@zone="a"]//node[@type="1"]', <<~XML).length
      <root>
        <nodes zone="a"><node type="1"></node><node type="2"></node></nodes>
        <nodes zone="b"><node type="1"></node><node type="2"></node></nodes>
      </root>
    XML
  end

  test 'should yield matching empty_element nodes' do
    assert_equal 2, @importer.nodes('//node', <<~XML).length
      <nodes><node/><node/></nodes>
    XML
  end

  test 'should yield nokogiri elements' do
    node = @importer.nodes('//node', <<~XML).first
      <nodes><node><foo>bar</foo></node></nodes>
    XML

    assert_kind_of Nokogiri::XML::Element, node
    assert_equal 'node', node.name
    assert_equal ['foo'], node.children.map(&:name)
    assert_equal 'bar', node.text
  end

  test 'stream_xml_nodes should handle incoming UTF-8' do
    nodes = @importer.nodes_from_file('//letter', 'utf-8_xml.xml')
    greek = nodes.map(&:text).join

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta
  end

  test 'stream_xml_nodes should handle incoming UTF-16 (big endian)' do
    nodes = @importer.nodes_from_file('//letter', 'utf-16be_xml.xml')
    greek = nodes.map(&:text).join

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta
  end

  test 'stream_xml_nodes should handle incoming UTF-16 (little endian)' do
    nodes = @importer.nodes_from_file('//letter', 'utf-16le_xml.xml')
    greek = nodes.map(&:text).join

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta
  end

  test 'stream_xml_nodes should handle incoming UTF-16 with declaration' do
    nodes = @importer.nodes_from_file('//note', 'utf-16be_xml_with_declaration.xml')
    greek = nodes.map(&:text).join.gsub(/\s/, '')

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta

    alpha_nodes = nodes.select { |node| node.at_xpath('//note[@id="alpha"]') }
    assert_equal 1, alpha_nodes.length
  end

  test 'stream_xml_nodes should handle incoming Windows-1252' do
    nodes = @importer.nodes_from_file('//letter', 'windows-1252_xml.xml')
    punct = nodes.map(&:text).join

    assert punct.valid_encoding?
    assert_equal Encoding.find('UTF-8'), punct.encoding
    assert_equal 2, punct.chars.to_a.length
    assert_equal [226, 128, 153, 226, 128, 147], punct.bytes.to_a # 3 bytes each for apostrophe and dash
  end

  test 'stream_xml_nodes with malformed XML file' do
    assert_raises Nokogiri::XML::SyntaxError do
      @importer.nodes_from_file('//note', 'malformed.xml')
    end
  end

  test 'stream_xml_nodes should reject non safe path arguments' do
    exception = assert_raises ArgumentError do
      @importer.send(:stream_xml_nodes, 'unsafe.xml', '//note')
    end

    assert_match(/should be of type SafePath/, exception.message)
  end
end
