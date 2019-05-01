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

    assert_match(/Invalid CSV format on row 2 of broken\.csv\./, exception.message)
    assert_match(CORRUPTED_QUOTES_MESSAGE_PATTERN, exception.message)
    assert_match(/in line 2/, exception.message)
  end

  test 'should be able to use liberal parsing to overcome minor CSV errors' do
    file_path = @permanent_test_files.join('malformed.csv')
    assert_raises(CSVLibrary::MalformedCSVError) do
      @importer.read_delimited_file(file_path, nil)
    end

    rows = @importer.read_delimited_file(file_path, nil, true)

    expected_row = ['2'] * 25
    expected_row << '2"malformed"'
    assert_equal expected_row, rows[2].sort
  end

  test 'should report addition details upon failure to read csv line-by-line' do
    rows_yielded = []
    exception    = assert_raises(CSVLibrary::MalformedCSVError) do
      @importer.delimited_rows(@permanent_test_files.join('broken.csv')) do |row|
        rows_yielded << row
      end
    end

    assert rows_yielded.empty?, 'no rows should have been yielded'

    assert_match(/Invalid CSV format on row 2 of broken\.csv\./, exception.message)
    assert_match(CORRUPTED_QUOTES_MESSAGE_PATTERN, exception.message)
    assert_match(/in line 2/, exception.message)
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
end
