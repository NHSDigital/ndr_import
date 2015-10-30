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
    @importer = TestImporter.new
  end

  test 'import_xml_file should handle incoming UTF-8' do
    doc   = @importer.send(:read_xml_file, @permanent_test_files.join('utf-8_xml.xml'))
    greek = doc.xpath('//letter').map(&:text).join

    assert_equal 'UTF-8', doc.encoding

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta
  end

  test 'import_xml_file should handle incoming UTF-16 (big endian)' do
    doc   = @importer.send(:read_xml_file, @permanent_test_files.join('utf-16be_xml.xml'))
    greek = doc.xpath('//letter').map(&:text).join

    assert_equal 'UTF-8', doc.encoding

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2-bytes each for alpha and beta
  end

  test 'import_xml_file should handle incoming UTF-16 (little endian)' do
    doc   = @importer.send(:read_xml_file, @permanent_test_files.join('utf-16le_xml.xml'))
    greek = doc.xpath('//letter').map(&:text).join

    assert_equal 'UTF-8', doc.encoding

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2 bytes each for alpha and beta
  end

  test 'import_xml_file should handle incoming UTF-16 with declaration' do
    doc   = @importer.send(:read_xml_file,
                           @permanent_test_files.join('utf-16be_xml_with_declaration.xml'))
    greek = doc.xpath('//letter').map(&:text).join

    assert greek.valid_encoding?
    assert_equal Encoding.find('UTF-8'), greek.encoding
    assert_equal 2, greek.chars.to_a.length
    assert_equal [206, 177, 206, 178], greek.bytes.to_a # 2 bytes each for alpha and beta

    # The document should be UTF-8, and we shouldn't
    # get encoding mismatches when interrogating it:
    assert_equal 'UTF-8', doc.encoding
    assert_equal 1, doc.css('note[id=alpha]').length
  end

  test 'import_xml_file should handle incoming Windows-1252' do
    doc   = @importer.send(:read_xml_file, @permanent_test_files.join('windows-1252_xml.xml'))
    punct = doc.xpath('//letter').map(&:text).join

    assert_equal 'UTF-8', doc.encoding

    assert punct.valid_encoding?
    assert_equal Encoding.find('UTF-8'), punct.encoding
    assert_equal 2, punct.chars.to_a.length
    assert_equal [226, 128, 153, 226, 128, 147], punct.bytes.to_a # 3 bytes each for apostrophe and dash
  end

  test 'import_xml_file with malformed XML file' do
    assert_raises Nokogiri::XML::SyntaxError do
      @importer.send(:read_xml_file, @permanent_test_files.join('malformed.xml'))
    end
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
