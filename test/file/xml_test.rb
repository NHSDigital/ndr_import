require 'test_helper'
require 'ndr_import/file/xml'

module NdrImport
  module File
    # Xml file handler tests
    class XmlTest < ActiveSupport::TestCase
      def setup
        @file_path = SafePath.new('permanent_test_files').join('sample.xml')
        @options   = { 'xml_record_xpath' => 'root/record' }
      end

      test 'should return enum of xml stream by default' do
        handler = NdrImport::File::Xml.new(@file_path, nil, @options)
        handler.expects(:read_xml_file).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end

      test 'should slurp xml only if asked' do
        handler = NdrImport::File::Xml.new(@file_path, nil, @options.merge('slurp' => true))
        handler.expects(:each_node).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end
    end
  end
end
