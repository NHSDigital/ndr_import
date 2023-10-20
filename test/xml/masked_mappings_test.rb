require 'test_helper'

# This tests the NdrImport::Xml::MaskedMapping class
module Xml
  class MaskedMappingsTest < ActiveSupport::TestCase
    test 'should build masked mappings with column specific klasses' do
      masked_mapping = NdrImport::Xml::MaskedMappings.new(nil, xml_column_mapping).call

      assert_equal expected_masked_mappings, masked_mapping
    end

    test 'should build masked mappings with table level klass' do
      masked_mapping = NdrImport::Xml::MaskedMappings.new('SomeTestKlass', xml_column_mapping).call

      assert_equal({ 'SomeTestKlass' => xml_column_mapping }, masked_mapping)
    end

    test 'should keep klasses when flagged to do so' do
      masked_mapping = NdrImport::Xml::MaskedMappings.new(nil, keep_klass_mapping).call

      assert_equal expected_keep_klass_masked_mapping, masked_mapping
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

    def keep_klass_mapping
      [
        { 'column' => 'no_relative_path', 'klass' => 'SomeTestKlass',
          'xml_cell' => { 'relative_path' => '', 'keep_klass' => true } },
        { 'column' => 'no_path_or_att', 'klass' => 'SomeTestKlass#1',
          'xml_cell' => { 'relative_path' => '', 'attribute' => '' } }
      ]
    end

    def expected_keep_klass_masked_mapping
      { 'SomeTestKlass' =>
        [{ 'column' => 'no_relative_path',
           'klass' => 'SomeTestKlass',
           'xml_cell' => { 'relative_path' => '', 'keep_klass' => true } },
         { 'do_not_capture' => true }],
        'SomeTestKlass#1' =>
        [{ 'do_not_capture' => true },
         { 'column' => 'no_path_or_att',
           'klass' => 'SomeTestKlass#1',
           'xml_cell' => { 'relative_path' => '', 'attribute' => '' } }] }
    end
  end
end
