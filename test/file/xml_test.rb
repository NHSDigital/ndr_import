require 'test_helper'
require 'ndr_import/file/xml'

module NdrImport
  module File
    # Xml file handler tests
    class XmlTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should return enum of xml elements' do
        file_path = @permanent_test_files.join('sample.xml')
        handler   = NdrImport::File::Xml.new(file_path, nil, 'root_node' => 'root/record')
        rows      = handler.send(:rows)
        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Nokogiri::XML::Element })
      end
    end
  end
end
