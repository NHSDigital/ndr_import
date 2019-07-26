require 'test_helper'
require 'ndr_import/helpers/file/xml_streaming'
require 'nokogiri'

# XML streaming file helper tests
class XmlTest < ActiveSupport::TestCase
  # This is a test importer class to test the XML streaming file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::XmlStreaming

    def nodes(xpath, xml)
      [].tap do |nodes|
        stream_xml_nodes(xml, xpath) { |node| nodes << node }
      end
    end
  end

  def setup
    @importer = TestImporter.new
  end

  test 'should yield matching nodes' do
    assert_equal 2, @importer.nodes('//node', <<~XML).length
      <nodes><node></node><node></node></nodes>
    XML
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
end
