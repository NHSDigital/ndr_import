require 'test_helper'
require 'ndr_import/helpers/file/xml'
require 'nokogiri'

# XML file helper tests
class XmlTest < ActiveSupport::TestCase
  # This is a test importer class to test the XML file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Xml
  end

  def setup
    @home = SafePath.new('test_space_rw')
    @permanent_test_files = SafePath.new('permanent_test_files')
    @importer  = TestImporter.new
  end

  test '.import_xml_file should reject non safe path arguments' do
    assert_raises ArgumentError do
      @importer.send(:read_xml_file, @home.join('simple.xml').to_s)
    end
  end

  test '.import_xml_file should accept safepath' do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.root do
        xml.note(:id => 1) do
          xml.time 'Thu Dec 13 13:12:00 UTC 2012'
          xml.title 'Note 1'
          xml.body 'Note 1 body blabla bla'
        end
        xml.note(:id => 2) do
          xml.time 'Thu Dec 14 12:11:00 UTC 2012'
          xml.title 'note 2'
          xml.body 'note 2 body blablabala'
        end
      end
    end
    SafeFile.open(@home.join('simple.xml'), 'w') { |f| f.write builder.to_xml }

    doc = @importer.send(:read_xml_file, @home.join('simple.xml'))

    assert_equal 1, doc.children.reject { |c| c.text =~ /\A\n *\Z/ }.length
    assert_equal 'root', doc.children.reject { |c| c.text =~ /\A\n *\Z/ }[0].name
    assert_equal 2, doc.
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }.length
    assert_equal 'note', doc.children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].name
    assert_equal 3, doc.
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }.length
    assert_equal 'Thu Dec 13 13:12:00 UTC 2012', doc.
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].
      children.reject { |c| c.text =~ /\A\n *\Z/ }[0].text

    SafeFile.delete @home.join('simple.xml')
  end
end
