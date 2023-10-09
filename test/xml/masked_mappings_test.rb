require 'test_helper'

# This tests the NdrImport::Xml::MaskedMapping class
module Xml
  class MaskedMappingsTest < ActiveSupport::TestCase
    def test_should_build_masked_mappings_with_column_specific_klasses
      masked_mapping = NdrImport::Xml::MaskedMappings.new(nil, xml_column_mapping).call

      assert_equal expected_masked_mappings, masked_mapping
    end

    def test_should_build_masked_mappings_with_table_level_klass
      masked_mapping = NdrImport::Xml::MaskedMappings.new('SomeTestKlass', xml_column_mapping).call

      assert_equal({ 'SomeTestKlass' => xml_column_mapping }, masked_mapping)
    end

    private

    def xml_column_mapping
      [
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass#bob',
          'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass',
          'rawtext_name' => 'no_relative_path_inner_text',
          'xml_cell' => { 'relative_path' => '' } },
        { 'column' => 'no_path_or_att', 'klass' => 'SomeTestKlass#1',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
        { 'column' => 'demographics_1', 'klass' => 'SomeTestKlass#1',
          'xml_cell' => { 'relative_path' => 'demographics' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass#2',
          'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
        { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass#2',
          'rawtext_name' => 'demographics_2_inner_text',
          'xml_cell' => { 'relative_path' => 'demographics' } }
      ]
    end

    def expected_masked_mappings
      { 'SomeTestKlass#bob' =>
        [{ 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass#bob',
           'xml_cell' => { 'relative_path' => '', 'attribute' => 'value' } },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true }],
        'SomeTestKlass#1' =>
        [{ 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'column' => 'no_path_or_att', 'klass' => 'SomeTestKlass#1',
           'xml_cell' => { 'relative_path' => '', 'attribute' => '' } },
         { 'column' => 'demographics_1', 'klass' => 'SomeTestKlass#1',
           'xml_cell' => { 'relative_path' => 'demographics' } },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true }],
        'SomeTestKlass#2' =>
        [{ 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'do_not_capture' => true },
         { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass#2',
           'xml_cell' => { 'relative_path' => 'demographics', 'attribute' => 'code' } },
         { 'column' => 'demographics_2', 'klass' => 'SomeTestKlass#2',
           'rawtext_name' => 'demographics_2_inner_text',
           'xml_cell' => { 'relative_path' => 'demographics' } }] }
    end
  end
end
