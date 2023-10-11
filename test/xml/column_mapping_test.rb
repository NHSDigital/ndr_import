require 'test_helper'

# This tests the NdrImport::Xml::ColumnMapping class
module Xml
  class ColumnMappingTest < ActiveSupport::TestCase
    def setup
      file_path = SafePath.new('permanent_test_files').join('sample.xml')
      options   = { 'xml_record_xpath' => 'record' }
      handler   = NdrImport::File::Xml.new(file_path, nil, options)

      rows = handler.send(:rows)
      @xml_line = rows.first
    end

    test 'should generate column for repeating item within a record' do
      existing_column = { 'column' => 'address_line1',
                          'klass' => 'SomeTestKlass',
                          'rawtext_name' => 'address',
                          'xml_cell' => {
                            'relative_path' => 'demographics/address',
                            'multiple' => true,
                            'build_new_record' => false
                          },
                          'mappings' => [{ 'field' => 'test_field' }] }

      unmapped_node_parts = { column_attribute: nil, column_name: 'address_line1[1]',
                              column_relative_path: 'demographics/address' }
      klass_increment = '1'
      klass = nil

      expected_column = { 'column' => 'address_line1[1]',
                          'klass' => 'SomeTestKlass',
                          'rawtext_name' => 'address_1',
                          'xml_cell' => {
                            'relative_path' => 'demographics/address',
                            'multiple' => true,
                            'build_new_record' => false
                          },
                          'mappings' => [{ 'field' => 'test_field' }] }

      new_column = NdrImport::Xml::ColumnMapping.new(existing_column, unmapped_node_parts,
                                                     klass_increment, @xml_line, klass).call

      assert_equal expected_column, new_column
    end

    test 'should generate a column with new klass' do
      existing_column = { 'column' => 'pathology_date',
                          'klass' => 'SomeTestKlass',
                          'xml_cell' => {
                            'relative_path' => 'pathology/sample', 'multiple' => true
                          } }
      unmapped_node_parts = { column_attribute: nil, column_name: 'pathology_date',
                              column_relative_path: 'pathology[1]/sample[1]' }
      klass_increment = '1'
      klass = nil

      expected_column = { 'column' => 'pathology_date',
                          'klass' => 'SomeTestKlass#1',
                          'xml_cell' => {
                            'relative_path' => 'pathology[1]/sample[1]', 'multiple' => true
                          },
                          'rawtext_name' => 'pathology_date_1' }

      new_column = NdrImport::Xml::ColumnMapping.new(existing_column, unmapped_node_parts,
                                                     klass_increment, @xml_line, klass).call

      assert_equal expected_column, new_column
    end
  end
end
