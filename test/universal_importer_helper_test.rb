require 'test_helper'
require 'ndr_import/universal_importer_helper'

# This tests the UniversalImporterHelper mixin
class UniversalImporterHelperTest < ActiveSupport::TestCase
  # This is a test importer class to test the excel file helper mixin
  class TestImporter
    include NdrImport::UniversalImporterHelper

    def initialize
      @table_mappings = [
        NdrImport::Table.new(filename_pattern: /\.xls\z/i,
                             tablename_pattern: /\Asheet1\z/i)
      ]
    end

    def get_notifier(_); end

    def unzip_path
      SafePath.new('test_space_rw')
    end
  end

  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
    @test_importer = TestImporter.new
  end

  test 'extract with matching mapping' do
    source_file = @permanent_test_files.join('sample_xls.xls')
    enumerator_ran = false
    @test_importer.extract(source_file) do |table, rows|
      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      enumerator_ran = true
    end
    assert enumerator_ran
  end

  test 'extract without matching mapping' do
    source_file = @permanent_test_files.join('sample_xlsx.xlsx')
    enumerator_ran = false
    @test_importer.extract(source_file) do |_table, _rows|
      enumerator_ran = true
    end
    refute enumerator_ran
  end

  test 'extract and transform with bespoke delimiter' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /\.txt\z/i,
                           format: 'delimited',
                           delimiter: '¬',
                           header_lines: 1,
                           footer_lines: 0,
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => 'one' },
                                     { 'column' => 'two' },
                                     { 'column' => 'three' }])
    ]
    source_file = @permanent_test_files.join('not_sign_delimited.txt')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { 'one' => 'some', 'two' => 'data', 'three' => 'here' } },
                              { rawtext: { 'one' => 'more', 'two' => 'data', 'three' => 'here' } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'extract with file_password' do
    table_mappings = load_esourcemapping_yaml(<<~YML)
      ---
      - !ruby/object:NdrImport::NonTabular::Table
          file_password: salad
          start_line_pattern: !ruby/regexp /must not match anything a2f76abe/
          start_in_a_record: true
          end_in_a_record: true
          klass: SomeTestKlass
          columns:
          - column: one
            non_tabular_cell:
              lines: !ruby/range
                begin: -1
                end: -1
                excl: false
              capture: !ruby/regexp /^(.*)$/i
    YML

    source_file = @permanent_test_files.join('password_protected_hello_world.docx')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::NonTabular::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { 'one' => 'Three in fact' } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'should only extract up to a specified last_data_column from xlsx' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /\.xlsx\z/i,
                           header_lines: 1,
                           footer_lines: 0,
                           last_data_column: 1,
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => '1a' }])
    ]
    source_file = @permanent_test_files.join('sample_xlsx.xlsx')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { '1a' => '2A' } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'should only extract up to a specified last_data_column from xls' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /\.xls\z/i,
                           header_lines: 1,
                           footer_lines: 0,
                           last_data_column: 1,
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => '1a' }])
    ]
    source_file = @permanent_test_files.join('sample_xls.xls')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { '1a' => '2A' } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'should only extract up to a specified last_data_column from delimited files' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /pipe/i,
                           header_lines: 1,
                           footer_lines: 0,
                           last_data_column: 'D',
                           format: 'delimited',
                           delimiter: '|',
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => 'a' },
                                     { 'column' => 'b' },
                                     { 'column' => 'c' },
                                     { 'column' => 'd' }])
    ]
    source_file = @permanent_test_files.join('normal_pipe.csv')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { 'a' => '1', 'b' => '1', 'c' => '1', 'd' => '1' } },
                              { rawtext: { 'a' => '2', 'b' => '2', 'c' => '2', 'd' => '2' } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'should only extract up to a specified last_data_column from JSON Lines files' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /array/i,
                           header_lines: 1,
                           footer_lines: 0,
                           last_data_column: 'D',
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => 'a' },
                                     { 'column' => 'b' },
                                     { 'column' => 'c' },
                                     { 'column' => 'd' }])
    ]
    source_file = @permanent_test_files.join('array.jsonl')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    @test_importer.extract(source_file) do |table, rows|
      mapped_rows = table.transform(rows)

      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      expected_mapped_data = [{ rawtext: { 'a' => 1, 'b' => 1, 'c' => 1, 'd' => 1 } },
                              { rawtext: { 'a' => 2, 'b' => 2, 'c' => 2, 'd' => 2 } }]

      assert_equal expected_mapped_data, (mapped_rows.to_a.map { |_klass, fields| fields })
    end
  end

  test 'multiple files using a single NdrImport::Table' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /\.txt\z/i,
                           canonical_name: 'a_table',
                           format: 'delimited',
                           delimiter: '¬',
                           header_lines: 1,
                           footer_lines: 0,
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => 'one' },
                                     { 'column' => 'two' },
                                     { 'column' => 'three' }])
    ]
    source_file = @permanent_test_files.join('two_files_single_table_mapping.zip')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    table_enums = @test_importer.table_enumerators(source_file)
    assert table_enums.one?
    assert_equal 4, table_enums.first.last.count
  end

  test 'mutated columns get reset' do
    table_mappings = [
      NdrImport::Table.new(filename_pattern: /\.csv\z/i,
                           canonical_name: 'a_table',
                           header_lines: 1,
                           footer_lines: 0,
                           klass: 'SomeTestClass',
                           columns: [{ 'column' => 'one' },
                                     { 'column' => 'two' },
                                     { 'column' => /\A[AB]\d{3}\z/i }])
    ]
    source_file = @permanent_test_files.join('regex_column_names.zip')
    @test_importer.stubs(:get_table_mapping).returns(table_mappings.first)
    mapped_rows = []
    @test_importer.extract(source_file) { |table, rows| mapped_rows << table.transform(rows).to_a }

    expected_mapped_data = [
      [['SomeTestClass', { rawtext: { 'one' => '2', 'two' => '2', 'b456' => '2' } }, 1]],
      [['SomeTestClass', { rawtext: { 'one' => '1', 'two' => '1', 'a123' => '1' } }, 1]]
    ]

    assert_equal expected_mapped_data, mapped_rows
  end

  test 'get_notifier' do
    class TestImporterWithoutNotifier
      include NdrImport::UniversalImporterHelper
    end

    assert_raise(NotImplementedError) do
      TestImporterWithoutNotifier.new.get_notifier(10_000)
    end
  end

  test 'should assign metadata to table when extracting' do
    table_mapping =
      NdrImport::Xml::Table.new(filename_pattern: /.xml/i,
                                yield_xml_record: true,
                                xml_record_xpath: 'BreastRecord',
                                format: 'xml_table',
                                xml_file_metadata: { record_count: '//COSD:RecordCount/@value' },
                                klass: 'SomeTestClass',
                                columns: {})

    source_file = @permanent_test_files.join('complex_xml.xml')
    @test_importer.stubs(:get_table_mapping).returns(table_mapping)
    @test_importer.extract(source_file) { |table, rows| table.transform(rows) }

    assert_equal({ record_count: '6349923' }, table_mapping.table_metadata)
  end
end
