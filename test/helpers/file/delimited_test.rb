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
    @importer  = TestImporter.new
  end

  test 'should read csv correctly' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('normal.csv'), nil)
    assert_equal ('A'..'Z').to_a, rows[0]
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read csv with a BOM' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('bomd.csv'), nil)
    assert_equal ('A'..'Z').to_a, rows[0]
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read windows-1252 csv' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('windows.csv'), nil)
    assert_equal 1, rows.length
  end

  test 'should read acsii-delimited csv' do
    rows = @importer.read_delimited_file(@permanent_test_files.join('high_ascii_delimited.txt'), "\xfe")
    assert_equal 2, rows.length
  end

  test 'should read line-by-line' do
    rows = []
    @importer.each_delimited_row(@permanent_test_files.join('normal.csv')) { |row| rows << row }
    assert_equal ('A'..'Z').to_a, rows[0]
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read line-by-line with custom delimiter' do
    count = 0
    file  = @permanent_test_files.join('high_ascii_delimited.txt')

    @importer.each_delimited_row(file, "\xfe") { |row| count += 1 }
    assert_equal 2, count
  end
end
