require 'test_helper'
require 'ndr_import/helpers/file/delimited'

# Delimited file helper tests
class DelimitedTest < ActiveSupport::TestCase
  # This is a test importer class to test the Delimited file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Delimited
  end

  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
    @importer = TestImporter.new
  end

  test 'should read csv correctly' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('normal.csv'), nil)
    assert_equal(('A'..'Z').to_a, rows[0])
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read csv with a BOM' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('bomd.csv'), nil)
    assert_equal(('A'..'Z').to_a, rows[0])
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read windows-1252 csv' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('windows.csv'), nil)
    assert_equal 1, rows.length
  end

  test 'should read acsii-delimited csv' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('high_ascii_delimited.txt'),
                                         "\xfe")
    assert_equal 2, rows.length
  end

  test 'should read line-by-line' do
    rows = []
    @importer.delimited_rows(@permanent_test_files.join('normal.csv')) { |row| rows << row }
    assert_equal(('A'..'Z').to_a, rows[0])
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read line-by-line with custom delimiter' do
    count = 0
    file  = @permanent_test_files.join('high_ascii_delimited.txt')

    @importer.delimited_rows(file, "\xfe") { count += 1 }
    assert_equal 2, count
  end

  test 'should report addition details upon failure to slurp csv' do
    exception = assert_raises(CSVLibrary::MalformedCSVError) do
      @importer.read_delimited_file(@permanent_test_files.join('broken.csv'), nil)
    end

    msg = 'Invalid CSV format on row 2 of broken.csv. Original: Missing or stray quote in line 2'
    assert_equal msg, exception.message
  end

  test 'should report addition details upon failure to read csv line-by-line' do
    rows_yielded = []
    exception    = assert_raises(CSVLibrary::MalformedCSVError) do
      @importer.delimited_rows(@permanent_test_files.join('broken.csv')) do |row|
        rows_yielded << row
      end
    end

    assert rows_yielded.empty?, 'no rows should have been yielded'

    msg = 'Invalid CSV format on row 2 of broken.csv. Original: Missing or stray quote in line 2'
    assert_equal msg, exception.message
  end

  test 'delimited_tables should read table correctly' do
    table = @importer.send(:delimited_tables, @permanent_test_files.join('normal.csv'))
    table.each do |tablename, sheet|
      assert_nil tablename
      sheet = sheet.to_a
      assert_equal(('A'..'Z').to_a, sheet[0])
      assert_equal ['1'] * 26, sheet[1]
      assert_equal ['2'] * 26, sheet[2]
    end
  end

  def test_deprecated_methods_removed_in_v3
    refute @importer.public_methods.include?(:each_delimited_table), 'should be removed in v4.0.0'
    refute @importer.public_methods.include?(:each_delimited_row), 'should be removed in v4.0.0'
  end if Gem::Requirement.new('>= 4.0.0').satisfied_by?(Gem::Version.new(NdrImport::VERSION))
end
