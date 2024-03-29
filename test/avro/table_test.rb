require 'test_helper'

# This tests the NdrImport::Avro::Table mapping class
module Avro
  class TableTest < ActiveSupport::TestCase
    def setup
      file_path = SafePath.new('permanent_test_files').join('fake_dids.avro')
      handler   = NdrImport::File::Avro.new(file_path, nil)

      @element_lines = handler.send(:rows)
    end

    test 'should transform avro lines' do
      table = NdrImport::Avro::Table.new(klass: 'SomeTestKlass', columns: avro_column_mapping)

      expected_data = ['SomeTestKlass', { rawtext: {
        'nhsnumber'                                  => '3200083271',
        'nhsnumberstatusindicatorcode'               => '01',
        'personbirthdate'                            => '1975-04-26',
        'ethniccategory'                             => 'A',
        'persongendercodecurrent'                    => '1',
        'postcodeofusualaddress'                     => 'ZP0M 5FL',
        'patientsourcesettingtype_diagnosticimaging' => '01',
        'referrercode'                               => 'C9999998',
        'referringorganisationcode'                  => 'RXD',
        'diagnostictestrequestdate'                  => '2022-03-28',
        'diagnostictestrequestreceiveddate'          => '2022-03-28',
        'diagnostictestdate'                         => '2022-04-11',
        'imagingcode_nicip'                          => 'NSMARO',
        'imagingcode_snomedct'                       => '',
        'servicereportissuedate'                     => '2022-04-14',
        'sitecode_ofimaging'                         => 'RH802',
        'radiologicalaccessionnumber'                => 'Mom39Xav13aodGX6C9tL'
      } }, 1]

      transformed_data = table.transform(@element_lines)
      assert_equal 10, transformed_data.count

      assert_equal expected_data, transformed_data.first
    end

    test 'should fail with too many columns of data' do
      table = NdrImport::Avro::Table.new(klass: 'SomeTestKlass',
                                         columns: unexpected_columns_mapping)

      exception = assert_raises(RuntimeError) { table.transform(@element_lines).to_a }
      expected_error = 'fake_dids.avro [RuntimeError: Header is not valid! unexpected: ' \
                       '["ethniccategory", "persongendercodecurrent"]]'
      assert_equal expected_error, exception.message
    end

    test 'should fail with missing columns of data' do
      table = NdrImport::Avro::Table.new(klass: 'SomeTestKlass',
                                         columns: missing_columns_mapping)

      exception = assert_raises(RuntimeError) { table.transform(@element_lines).to_a }
      expected_error = 'fake_dids.avro [RuntimeError: Header is not valid! missing: ' \
                       '["missing_column_one", "missing_column_two"]]'
      assert_equal expected_error, exception.message
    end

    test 'should scaffold table mappings from avro schema file' do
      schema_safe_path         = SafePath.new('permanent_test_files').join('fake_dids.avsc')
      scaffolded_table_mapping = NdrImport::Avro::Table.from_schema(schema_safe_path)

      assert scaffolded_table_mapping.is_a? NdrImport::Avro::Table

      expected_column_mappings = [
        { column: 'NHSNUMBER' },
        { column: 'NHSNUMBERSTATUSINDICATORCODE' },
        { column: 'PERSONBIRTHDATE',
          mappings: { field: 'PERSONBIRTHDATE', daysafter: '1970-01-01' } },
        { column: 'ETHNICCATEGORY' },
        { column: 'PERSONGENDERCODECURRENT' },
        { column: 'POSTCODEOFUSUALADDRESS' },
        { column: 'PATIENTSOURCESETTINGTYPE_DIAGNOSTICIMAGING' },
        { column: 'REFERRERCODE' },
        { column: 'REFERRINGORGANISATIONCODE' },
        { column: 'DIAGNOSTICTESTREQUESTDATE',
          mappings: { field: 'DIAGNOSTICTESTREQUESTDATE', daysafter: '1970-01-01' } },
        { column: 'DIAGNOSTICTESTREQUESTRECEIVEDDATE',
          mappings: { field: 'DIAGNOSTICTESTREQUESTRECEIVEDDATE', daysafter: '1970-01-01' } },
        { column: 'DIAGNOSTICTESTDATE',
          mappings: { field: 'DIAGNOSTICTESTDATE', daysafter: '1970-01-01' } },
        { column: 'IMAGINGCODE_NICIP' },
        { column: 'IMAGINGCODE_SNOMEDCT' },
        { column: 'SERVICEREPORTISSUEDATE',
          mappings: { field: 'SERVICEREPORTISSUEDATE', daysafter: '1970-01-01' } },
        { column: 'SITECODE_OFIMAGING' },
        { column: 'RADIOLOGICALACCESSIONNUMBER' }
      ]

      assert_equal expected_column_mappings, scaffolded_table_mapping.columns
      assert_equal '/fake_dids.avro\z/', scaffolded_table_mapping.filename_pattern
      assert_equal 'ExampleKlass', scaffolded_table_mapping.klass
    end

    test 'should raise security error when schema path is not a safe path' do
      assert_raises(SecurityError) { NdrImport::Avro::Table.from_schema('not a safe path') }
    end

    private

    def avro_column_mapping
      [{ 'column' => 'nhsnumber' },
       { 'column' => 'nhsnumberstatusindicatorcode' },
       { 'column' => 'personbirthdate' },
       { 'column' => 'ethniccategory' },
       { 'column' => 'persongendercodecurrent' },
       { 'column' => 'postcodeofusualaddress' },
       { 'column' => 'patientsourcesettingtype_diagnosticimaging' },
       { 'column' => 'referrercode' },
       { 'column' => 'referringorganisationcode' },
       { 'column' => 'diagnostictestrequestdate' },
       { 'column' => 'diagnostictestrequestreceiveddate' },
       { 'column' => 'diagnostictestdate' },
       { 'column' => 'imagingcode_nicip' },
       { 'column' => 'imagingcode_snomedct' },
       { 'column' => 'servicereportissuedate' },
       { 'column' => 'sitecode_ofimaging' },
       { 'column' => 'radiologicalaccessionnumber' }]
    end

    def unexpected_columns_mapping
      [{ 'column' => 'nhsnumber' },
       { 'column' => 'nhsnumberstatusindicatorcode' },
       { 'column' => 'personbirthdate' },
       { 'column' => 'postcodeofusualaddress' },
       { 'column' => 'patientsourcesettingtype_diagnosticimaging' },
       { 'column' => 'referrercode' },
       { 'column' => 'referringorganisationcode' },
       { 'column' => 'diagnostictestrequestdate' },
       { 'column' => 'diagnostictestrequestreceiveddate' },
       { 'column' => 'diagnostictestdate' },
       { 'column' => 'imagingcode_nicip' },
       { 'column' => 'imagingcode_snomedct' },
       { 'column' => 'servicereportissuedate' },
       { 'column' => 'sitecode_ofimaging' },
       { 'column' => 'radiologicalaccessionnumber' }]
    end

    def missing_columns_mapping
      [{ 'column' => 'nhsnumber' },
       { 'column' => 'nhsnumberstatusindicatorcode' },
       { 'column' => 'personbirthdate' },
       { 'column' => 'ethniccategory' },
       { 'column' => 'persongendercodecurrent' },
       { 'column' => 'postcodeofusualaddress' },
       { 'column' => 'patientsourcesettingtype_diagnosticimaging' },
       { 'column' => 'referrercode' },
       { 'column' => 'referringorganisationcode' },
       { 'column' => 'diagnostictestrequestdate' },
       { 'column' => 'diagnostictestrequestreceiveddate' },
       { 'column' => 'diagnostictestdate' },
       { 'column' => 'imagingcode_nicip' },
       { 'column' => 'imagingcode_snomedct' },
       { 'column' => 'servicereportissuedate' },
       { 'column' => 'sitecode_ofimaging' },
       { 'column' => 'missing_column_one' },
       { 'column' => 'missing_column_two' },
       { 'column' => 'radiologicalaccessionnumber' }]
    end
  end
end
