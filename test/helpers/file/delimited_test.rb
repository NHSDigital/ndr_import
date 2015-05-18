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
    rows = @importer.send(:read_delimited_file, @permanent_test_files.join('normal.csv'), nil)
    assert_equal ('A'..'Z').to_a, rows[0]
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read csv with a BOM' do
    rows = @importer.send(:read_delimited_file, @permanent_test_files.join('bomd.csv'), nil)
    assert_equal ('A'..'Z').to_a, rows[0]
    assert_equal ['1'] * 26, rows[1]
    assert_equal ['2'] * 26, rows[2]
  end

  test 'should read windows-1252 csv' do
    assert_nothing_raised do
      rows = @importer.send(:read_delimited_file, @permanent_test_files.join('windows.csv'), nil)
      assert_equal 1, rows.length
    end
  end

  test 'should read acsii-delimited csv' do
    assert_nothing_raised do
      rows = @importer.send(:read_delimited_file, @permanent_test_files.join('high_ascii_delimited.txt'), "\xfe")
      puts rows.inspect
      assert_equal 2, rows.length
    end
  end
end
