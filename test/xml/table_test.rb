require 'test_helper'

# This tests the NdrImport::Xml::Table mapping class
module Xml
  class TableTest < ActiveSupport::TestCase
    def setup
      file_path = SafePath.new('permanent_test_files').join('sample.xml')
      handler   = NdrImport::File::Xml.new(file_path, nil, 'xml_record_xpath' => 'record')

      @element_lines = handler.send(:rows)
    end

    def test_should_transform_xml_element_lines
      table = NdrImport::Xml::Table.new(klass: 'SomeTestKlass', columns: xml_column_mapping)

      expected_data = ['SomeTestKlass', { rawtext: {
        'no_relative_path'            => 'A value',
        'no_relative_path_inner_text' => '',
        'no_path_or_att'              => 'Another value',
        'demographics_1'              => 'AAA',
        'demographics_2'              => '03',
        'demographics_2_inner_text'   => 'Inner text',
        'address1'                    => 'Address',
        'address2'                    => 'Address 2',
        'pathology_date_1'            => '2018-01-01',
        'pathology_date_2'            => '',
        'should_be_blank'             => ''
      } }, 1]

      transformed_data = table.transform(@element_lines)
      assert_equal 2, transformed_data.count

      transformed_data.each do |klass, fields, _index|
        assert_equal expected_data[0], klass
        assert_equal expected_data[1], fields
      end
    end

    def test_should_fail_with_unmappped_nodes
      table = NdrImport::Xml::Table.new(klass: 'SomeTestKlass', columns: partial_xml_column_mapping)

      exception = assert_raises(RuntimeError) { table.transform(@element_lines).to_a }
      assert exception.message.starts_with? 'sample.xml [RuntimeError: Unmapped data!'
    end

    def test_should_not_raise_exception_on_forced_slurp
      NdrImport::Xml::Table.new(klass: 'SomeTestKlass', slurp: true, columns: xml_column_mapping)
    end

    private

    def xml_column_mapping
      [
        { 'column' => 'no_relative_path',
          'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
        { 'column' => 'no_relative_path', 'rawtext_name' => 'no_relative_path_inner_text',
          'xml_cell' => { 'relative_path' => '' } },
        { 'column' => 'no_path_or_att',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
        { 'column' => 'demographics_1',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'demographics_2',
          'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
        { 'column' => 'demographics_2', 'rawtext_name' => 'demographics_2_inner_text',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'address_line1[1]', 'rawtext_name' => 'address1',
          'xml_cell' => { 'relative_path' => 'demographics/address' } },
        { 'column' => 'address_line1[2]', 'rawtext_name' => 'address2',
          'xml_cell' => { 'relative_path' => 'demographics/address' } },
        { 'column' => 'pathology_date_1',
          'xml_cell' => { 'relative_path' => 'pathology' } },
        { 'column' => 'pathology_date_2',
          'xml_cell' => { 'relative_path' => 'pathology' } },
        { 'column' => 'should_be_blank',
          'xml_cell' => { 'relative_path' => 'not_present' } }
      ]
    end

    def partial_xml_column_mapping
      [
        { 'column' => 'no_relative_path',
          'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
        { 'column' => 'no_path_or_att',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
        { 'column' => 'demographics_1',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'demographics_2',
          'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
        { 'column' => 'address_line1',
          'xml_cell' => { 'relative_path' => 'demographics/address' } }
      ]
    end
  end
end
