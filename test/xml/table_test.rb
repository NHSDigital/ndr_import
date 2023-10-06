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

    def test_should_augment_columns_for_repeating_sections
      file_path     = SafePath.new('permanent_test_files').join('repeating_section_sample.xml')
      handler       = NdrImport::File::Xml.new(file_path, nil, 'xml_record_xpath' => 'record')
      element_lines = handler.send(:rows)
      table         = NdrImport::Xml::Table.new(columns: repeating_secion_xml_mapping)

      # Trigger the augmentation logic
      table.transform(element_lines).first
      new_columns = table.columns - repeating_secion_xml_mapping
      assert_equal augmented_xml_columns, new_columns
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

    def repeating_secion_xml_mapping
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

    # These columns are made on the fly by the Table
    def augmented_xml_columns
      [{ 'column' => 'address_line1[1]', 'klass' => 'SomeTestKlass',
         'rawtext_name' => 'address_1',
         'xml_cell' =>  { 'relative_path' => 'demographics/address',
                          'multiple' => true,
                          'build_new_record' => false }},
       { 'column' => 'address_line1[2]', 'klass' => 'SomeTestKlass',
         'rawtext_name' => 'address_2',
         'xml_cell' => { 'relative_path' => 'demographics/address',
                         'multiple' => true,
                         'build_new_record' => false }},
       { 'column' => 'pathology_date', 'klass' => 'SomeTestKlass#1',
         'xml_cell' => { 'relative_path' => 'pathology[1]/sample[1]', 'multiple' => true },
         'rawtext_name' => 'pathology_date_1' },
       { 'column' => 'pathology_id', 'klass' => 'SomeTestKlass#1',
         'xml_cell' => { 'relative_path' => 'pathology[1]/sample[1]', 'multiple' => true },
         'rawtext_name' => 'pathology_id_1' },
       { 'column' => 'pathology_date', 'klass' => 'SomeTestKlass#1',
         'xml_cell' => { 'relative_path' => 'pathology[1]/sample[2]', 'multiple' => true },
         'rawtext_name' => 'pathology_date_2' },
       { 'column' => 'pathology_id', 'klass' => 'SomeTestKlass#1',
         'xml_cell' => { 'relative_path' => 'pathology[1]/sample[2]', 'multiple' => true },
         'rawtext_name' => 'pathology_id_2' },
       { 'column' => 'pathology_date', 'klass' => 'SomeTestKlass#2',
         'xml_cell' => { 'relative_path' => 'pathology[2]/sample', 'multiple' => true },
         'rawtext_name' => 'pathology_date' },
       { 'column' => 'pathology_id', 'klass' => 'SomeTestKlass#2',
         'xml_cell' => { 'relative_path' => 'pathology[2]/sample', 'multiple' => true },
         'rawtext_name' => 'pathology_id' }]
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
