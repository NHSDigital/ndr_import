require 'test_helper'
require 'ndr_import/file/xml'

module NdrImport
  module File
    # Xml file handler tests
    class XmlTest < ActiveSupport::TestCase
      def setup
        @file_path = SafePath.new('permanent_test_files').join('sample.xml')
      end

      test 'should return enum of xml stream by default' do
        options = { 'xml_record_xpath' => 'record' }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:read_xml_file).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end

      test 'should slurp xml only if asked' do
        options = { 'xml_record_xpath' => 'record',
                    'slurp' => true }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:each_node).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end

      test 'should pattern match xpaths if asked' do
        options = { 'pattern_match_record_xpath' => true,
                    'xml_record_xpath' => '\Arecord\z',
                    'slurp' => true }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:each_node).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end

      test 'should pattern match xpaths when streaming if asked' do
        options = { 'pattern_match_record_xpath' => true,
                    'xml_record_xpath' => '\Arecord\z' }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:read_xml_file).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
        assert_equal 2, rows.to_a.length
      end

      test 'should skip non-matching xpaths' do
        options = { 'pattern_match_record_xpath' => true,
                    'xml_record_xpath' => '\Anon_matching_record\z',
                    'slurp' => true }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:each_node).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert_equal 0, rows.to_a.length
      end

      test 'should skip non-matching xpaths when streaming' do
        options = { 'pattern_match_record_xpath' => true,
                    'xml_record_xpath' => '\Anon_matching_record\z' }
        handler = NdrImport::File::Xml.new(@file_path, nil, options)
        handler.expects(:read_xml_file).never

        rows = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert_equal 0, rows.to_a.length
      end
    end
  end
end
