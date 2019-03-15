require 'test_helper'

# This tests the NdrImport::PdfForm::Table mapping class
module PdfForm
  class TableTest < ActiveSupport::TestCase
    def setup
      @form_data = [{
        'address2'        => 'Address 2',
        'should_be_blank' => '',
        'date_2'          => '2018-12-01',
        'date_1'          => '2018-01-01',
        'address1'        => 'Address'
      }]
    end

    def test_should_transform_pdf_form_hash
      table = NdrImport::PdfForm::Table.new(klass: 'SomeTestKlass',
                                            columns: pdf_form_column_mapping)

      assert_equal 'acroform', table.format

      transformed_data = table.transform(@form_data)
      assert_equal 1, transformed_data.count

      expected_data = ['SomeTestKlass', { rawtext: {
        'address1'          => 'Address',
        'address2'          => 'Address 2',
        'missing_from_data' => '',
        'date_1'            => '2018-01-01',
        'date_2'            => '2018-12-01',
        'should_be_blank'   => ''
      } }, 0]

      klass, fields, index = *transformed_data.first
      assert_equal expected_data[0],  klass
      assert_equal expected_data[1],  fields
      assert_equal expected_data[-1], index
    end

    def test_should_transform_mutli_klass_pdf_form_hash
      table = NdrImport::PdfForm::Table.new(columns: multi_klass_pdf_form_column_mapping)

      expected_data = [
        ['TestKlassOne',
         { rawtext:
           { 'address1'          => 'Address',
             'address2'          => 'Address 2',
             'missing_from_data' => '' } },
         0],
        ['TestKlassTwo',
         { rawtext:
           { 'address1'        => 'Address',
             'date_1'          => '2018-01-01',
             'date_2'          => '2018-12-01',
             'should_be_blank' => '' } },
         0]
      ]

      transformed_data = table.transform(@form_data).to_a
      assert_equal 2, transformed_data.count

      expected_data.each_with_index do |expected, index|
        transformed = transformed_data[index]
        assert_equal expected, transformed
      end
    end

    def test_should_fail_with_unmappped_form_data
      table = NdrImport::PdfForm::Table.new(klass: 'SomeTestKlass',
                                            columns: partial_pdf_form_column_mapping)

      exception = assert_raises(NdrImport::UnmappedDataError) { table.transform(@form_data).to_a }
      assert exception.message == 'Unmapped data: address2 and date_1'
    end

    def test_should_not_be_valid_with_bespoke_format
      exception = assert_raises(ArgumentError) { NdrImport::PdfForm::Table.new(format: 'a_format') }
      exception.message == 'Unrecognised options: ["format"]'
    end

    private

    def pdf_form_column_mapping
      [
        { 'column' => 'address1' },
        { 'column' => 'address2' },
        { 'column' => 'missing_from_data' },
        { 'column' => 'date_1' },
        { 'column' => 'date_2' },
        { 'column' => 'should_be_blank' }
      ]
    end

    def multi_klass_pdf_form_column_mapping
      [
        { 'column' => 'address1',
          'klass'  => %w[TestKlassOne TestKlassTwo] },
        { 'column' => 'address2',
          'klass'  => 'TestKlassOne' },
        { 'column' => 'missing_from_data',
          'klass'  => 'TestKlassOne' },
        { 'column' => 'date_1',
          'klass'  => 'TestKlassTwo' },
        { 'column' => 'date_2',
          'klass'  => 'TestKlassTwo' },
        { 'column' => 'should_be_blank',
          'klass'  => 'TestKlassTwo' }
      ]
    end

    def partial_pdf_form_column_mapping
      [
        { 'column' => 'address1' },
        { 'column' => 'date_2' },
        { 'column' => 'should_be_blank' }
      ]
    end
  end
end
