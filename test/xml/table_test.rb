require 'test_helper'

module Xml
  # This tests the NdrImport::Xml::Table mapping class
  class TableTest < ActiveSupport::TestCase
    def setup
      file_path = SafePath.new('permanent_test_files').join('sample.xml')
      handler   = NdrImport::File::Xml.new(file_path, nil, 'xml_record_xpath' => 'record')

      @element_lines = handler.send(:rows)
    end

    test 'test should transform xml element lines' do
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

    test 'test should fail with unmappped nodes' do
      table = NdrImport::Xml::Table.new(klass: 'SomeTestKlass', columns: partial_xml_column_mapping)

      exception = assert_raises NdrImport::Xml::UnmappedXpathError do
        table.transform(@element_lines).to_a
      end
      expected_error = 'Unmapped xpath(s): pathology/pathology_date_1 ' \
                       'and pathology/pathology_date_2'
      assert_equal expected_error, exception.message
    end

    test 'test should not raise exception on forced slurp' do
      NdrImport::Xml::Table.new(klass: 'SomeTestKlass', slurp: true, columns: xml_column_mapping)
    end

    test 'test should augment columns for repeating sections' do
      file_path     = SafePath.new('permanent_test_files').join('repeating_section_sample.xml')
      handler       = NdrImport::File::Xml.new(file_path, nil, 'xml_record_xpath' => 'record')
      element_lines = handler.send(:rows)
      table         = NdrImport::Xml::Table.new(columns: repeating_section_xml_mapping)

      expected_data = [
        ['SomeTestKlass#1', { rawtext:
           { 'pathology_date_1.1' => '2018-01-01', 'pathology_id_1.1' => 'AAA',
             'pathology_date_1.2' => '2019-01-01', 'pathology_id_1.2' => 'BBB' } },
         0],
        ['SomeTestKlass#2', { rawtext:
          { 'pathology_date_2' => '2020-01-01', 'pathology_id_2' => 'CCC' } },
         0],
        ['SomeTestKlass#1', { rawtext:
          { 'pathology_date_1' => '2021-01-01', 'pathology_id_1' => 'DDD' } },
         1],
        ['SomeTestKlass#2', { rawtext:
          { 'pathology_date_2' => '2022-01-01', 'pathology_id_2' => 'EEE' } },
         1],
        ['SomeTestKlass', { rawtext:
          { 'no_relative_path' => 'A value', 'no_path_or_att' => 'Another value',
            'demographics_1' => 'AAA', 'demographics_2' => '03',
            'demographics_2_inner_text' => 'Inner text', 'address' => '',
            'pathology_date' => '2023-01-01', 'pathology_id' => 'FFF',
            'should_be_blank' => '', 'address_1' => 'Address', 'address_2' => 'Address 2' } },
         2]
      ]

      # Trigger the augmentation logic
      transformed_data = table.transform(element_lines).to_a

      assert_equal expected_data, transformed_data
    end

    test 'complex xml test' do
      file_path = SafePath.new('permanent_test_files').join('complex_xml.xml')
      handler   = NdrImport::File::Xml.new(file_path, nil,
                                           'xml_record_xpath' => 'BreastRecord',
                                           'slurp' => true)
      xml_lines = handler.send(:rows)

      mapping_file_path = SafePath.new('permanent_test_files').join('complex_xml_mapping.yml')

      table = load_esourcemapping_yaml(File.read(mapping_file_path, mode: 'r:bom|utf-8'))

      expected_mapped_lines = YAML.load_file SafePath.new('permanent_test_files').
                              join('complex_xml_transformed.yml')

      assert_equal expected_mapped_lines, table.transform(xml_lines).to_a

      expected_xpaths = YAML.load_file SafePath.new('permanent_test_files').
                        join('complex_xml_augmented_xpaths.yml')
      assert_equal expected_xpaths, table.instance_variable_get('@augmented_column_xpaths')

      expected_columns_filepath = SafePath.new('permanent_test_files').
                                  join('complex_xml_augmented_column_mappings.yml')
      expected_column_mappings = load_esourcemapping_yaml(File.read(expected_columns_filepath,
                                                                    mode: 'r:bom|utf-8'))
      assert_equal expected_column_mappings, table.instance_variable_get('@augmented_columns')
    end

    test 'should create unique column mappings' do
      file_path = SafePath.new('permanent_test_files').join('unique_column_mapping_example.xml')
      handler   = NdrImport::File::Xml.new(file_path, nil,
                                           'xml_record_xpath' => 'record',
                                           'slurp' => true)

      xml_lines = handler.send(:rows)
      table     = NdrImport::Xml::Table.new(columns: unique_column_mapping_xml)

      expected_mapped_lines =
        [['SomeTestKlass',
          { 'data_item_1.1' => '01',
            'data_item_1.2' => '02',
            'data_item_2.1' => '03',
            'data_item_2.2' => '04',
            :rawtext =>
            { 'data_item' => '',
              'data_item_1.1' => '01',
              'data_item_1.2' => '02',
              'data_item_2.1' => '03',
              'data_item_2.2' => '04' } },
          0]]
      assert_equal expected_mapped_lines, table.transform(xml_lines).to_a

      expected_column_xpaths = [
        'Section/SubSection/data_item/@code',
        'Section[1]/SubSection[1]/data_item/@code',
        'Section[1]/SubSection[2]/data_item/@code',
        'Section[2]/SubSection[1]/data_item/@code',
        'Section[2]/SubSection[2]/data_item/@code'
      ]
      assert_equal expected_column_xpaths, table.instance_variable_get('@augmented_column_xpaths')

      expected_augmented_columns = [
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' => {
            'relative_path' => 'Section/SubSection',
            'attribute' => 'code',
            'multiple' => true,
            'increment_field_name' => true,
            'build_new_record' => false
          },
          'mappings' => [{ 'field' => 'data_item' }] },
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' =>
          { 'relative_path' => 'Section[1]/SubSection[1]',
            'attribute' => 'code',
            'multiple' => true,
            'increment_field_name' => true,
            'build_new_record' => false },
          'mappings' => [{ 'field' => 'data_item_1.1' }],
          'rawtext_name' => 'data_item_1.1' },
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' =>
          { 'relative_path' => 'Section[1]/SubSection[2]',
            'attribute' => 'code',
            'multiple' => true,
            'increment_field_name' => true,
            'build_new_record' => false },
          'mappings' => [{ 'field' => 'data_item_1.2' }],
          'rawtext_name' => 'data_item_1.2' },
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' =>
          { 'relative_path' => 'Section[2]/SubSection[1]',
            'attribute' => 'code',
            'multiple' => true,
            'increment_field_name' => true,
            'build_new_record' => false },
          'mappings' => [{ 'field' => 'data_item_2.1' }],
          'rawtext_name' => 'data_item_2.1' },
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' =>
          { 'relative_path' => 'Section[2]/SubSection[2]',
            'attribute' => 'code',
            'multiple' => true,
            'increment_field_name' => true,
            'build_new_record' => false },
          'mappings' => [{ 'field' => 'data_item_2.2' }],
          'rawtext_name' => 'data_item_2.2' }
      ]

      assert_equal expected_augmented_columns, table.instance_variable_get('@augmented_columns')
    end

    private

    def xml_column_mapping
      [
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'no_relative_path_inner_text',
          'xml_cell' => { 'relative_path' => '' } },
        { 'column' => 'no_path_or_att', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
        { 'column' => 'demographics_1', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'demographics_2_inner_text',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'address_line1[1]', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'address1',
          'xml_cell' => { 'relative_path' => 'demographics/address' } },
        { 'column' => 'address_line1[2]', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'address2',
          'xml_cell' => { 'relative_path' => 'demographics/address' } },
        { 'column' => 'pathology_date_1', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'pathology' } },
        { 'column' => 'pathology_date_2', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'pathology' } },
        { 'column' => 'should_be_blank', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'not_present' } }
      ]
    end

    def repeating_section_xml_mapping
      [
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
        { 'column' => 'no_path_or_att', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
        { 'column' => 'demographics_1', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'demographics_2_inner_text',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'address_line1', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'address',
          'xml_cell' =>
            { 'relative_path' => 'demographics/address',
              'multiple' => true,
              'build_new_record' => false } },
        { 'column' => 'pathology_date', 'klass' => 'SomeTestKlass',
          'xml_cell' =>
            { 'relative_path' => 'pathology/sample',
              'multiple' => true } },
        { 'column' => 'pathology_id', 'klass' => 'SomeTestKlass',
          'xml_cell' =>
            { 'relative_path' => 'pathology/sample',
              'multiple' => true } },
        { 'column' => 'should_be_blank', 'klass' => 'SomeTestKlass',
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

    def unique_column_mapping_xml
      [
        { 'column' => 'data_item',
          'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => 'Section/SubSection', 'attribute' => 'code',
                          'multiple' => true, 'increment_field_name' => true,
                          'build_new_record' => false },
          'mappings' => ['field' => 'data_item'] }
      ]
    end
  end
end
