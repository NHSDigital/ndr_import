require 'test_helper'
require 'ndr_import/file/delimited'

module NdrImport
  module File
    # Delimited file handler tests
    class DelimitedTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read csv correctly' do
        file_path = @permanent_test_files.join('normal.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          sheet = sheet.to_a
          assert_equal(('A'..'Z').to_a, sheet[0])
          assert_equal ['1'] * 26, sheet[1]
          assert_equal ['2'] * 26, sheet[2]
        end
      end

      test 'should read pipe correctly' do
        file_path = @permanent_test_files.join('normal_pipe.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'delimited', 'col_sep' => '|')
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          sheet = sheet.to_a
          assert_equal(('A'..'Z').to_a, sheet[0])
          assert_equal ['1'] * 26, sheet[1]
          assert_equal ['2'] * 26, sheet[2]
        end
      end

      test 'should read unconformat pipe correctly' do
        file_path = @permanent_test_files.join('malformed_pipe.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'delimited', 'col_sep' => '|',
                                                                         'liberal_parsing' => 'true')
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          sheet = sheet.to_a
          assert_equal(('A'..'Z').to_a, sheet[0])
          assert_equal ['1'] * 26, sheet[1]
          expected_row = ['2'] * 25
          expected_row << '2"malformed"'
          assert_equal expected_row, sheet[2].sort
        end
      end

      test 'should read thorn correctly' do
        file_path = @permanent_test_files.join('normal_thorn.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'delimited', 'col_sep' => "\xfe")
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          sheet = sheet.to_a
          assert_equal(('A'..'Z').to_a, sheet[0])
          assert_equal ['1'] * 26, sheet[1]
          assert_equal ['2'] * 26, sheet[2]
        end
      end

      test 'should read csv with a BOM' do
        file_path = @permanent_test_files.join('bomd.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet = sheet.to_a
          assert_equal(('A'..'Z').to_a, sheet[0])
          assert_equal ['1'] * 26, sheet[1]
          assert_equal ['2'] * 26, sheet[2]
        end
      end

      test 'should read windows-1252 csv' do
        file_path = @permanent_test_files.join('windows.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet = sheet.to_a
          assert_equal 1, sheet.length
        end
      end

      test 'should read acsii-delimited csv' do
        file_path = @permanent_test_files.join('high_ascii_delimited.txt')
        handler = NdrImport::File::Delimited.new(file_path, 'delimited', 'col_sep' => "\xfe")
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet = sheet.to_a
          assert_equal 2, sheet.length
          assert_equal '1234567890', sheet[0][1]
          assert_equal '1234567890', sheet[1][1]
        end
      end

      test 'should read acsii-delimited txt' do
        rows = []
        file_path = @permanent_test_files.join('high_ascii_delimited_example_two.txt')
        handler = NdrImport::File::Delimited.new(file_path, 'delimited', 'col_sep' => "\xfd")
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet.each do |row|
            rows << row
          end
        end

        assert_equal(('A'..'Z').to_a, rows[0])
        assert_equal ['1'] * 26, rows[1]
        assert_equal ['2'] * 26, rows[2]
      end

      test 'should read malformed delimited txt' do
        rows = []
        file_path = @permanent_test_files.join('malformed.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil,
                                                                   'liberal_parsing' => 'true')
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet.each do |row|
            rows << row
          end
        end

        assert_equal(('A'..'Z').to_a, rows[0])
        assert_equal ['1'] * 26, rows[1]
        expected_row = ['2'] * 25
        expected_row << '2"malformed"'
        assert_equal expected_row, rows[2].sort
      end

      test 'should fail to read malformed delimited txt without liberal_parsing' do
        rows_yielded = []
        exception    = assert_raises(CSVLibrary::MalformedCSVError) do
          file_path = @permanent_test_files.join('malformed.csv')
          handler = NdrImport::File::Delimited.new(file_path, 'csv')

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.each do |row|
              rows_yielded << row
            end
          end
        end

        assert rows_yielded.empty?, 'no rows should have been yielded'

        msg = 'Invalid CSV format on row 3 of malformed.csv. Original: Illegal quoting in line 3.'
        assert_equal msg, exception.message
      end

      test 'should read line-by-line' do
        rows = []
        file_path = @permanent_test_files.join('normal.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv')

        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          sheet.each do |row|
            rows << row
          end
        end

        assert_equal(('A'..'Z').to_a, rows[0])
        assert_equal ['1'] * 26, rows[1]
        assert_equal ['2'] * 26, rows[2]
      end

      test 'should report addition details upon failure to slurp csv' do
        exception = assert_raises(CSVLibrary::MalformedCSVError) do
          file_path = @permanent_test_files.join('broken.csv')
          handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil)

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end

        msg = 'Invalid CSV format on row 2 of broken.csv. ' \
              'Original: Missing or stray quote in line 2'
        assert_equal msg, exception.message
      end

      test 'should report addition details upon failure to read csv line-by-line' do
        rows_yielded = []
        exception    = assert_raises(CSVLibrary::MalformedCSVError) do
          file_path = @permanent_test_files.join('broken.csv')
          handler = NdrImport::File::Delimited.new(file_path, 'csv')

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.each do |row|
              rows_yielded << row
            end
          end
        end

        assert rows_yielded.empty?, 'no rows should have been yielded'

        msg = 'Invalid CSV format on row 2 of broken.csv. ' \
              'Original: Missing or stray quote in line 2'
        assert_equal msg, exception.message
      end

      test 'should only determine encodings once' do
        file_path = @permanent_test_files.join('normal.csv')
        handler = NdrImport::File::Delimited.new(file_path, 'csv', 'col_sep' => nil)

        handler.expects(determine_encodings!: { mode: 'r:bom|utf-8', col_sep: ',' }).once

        2.times do
          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            sheet = sheet.to_a
            assert_equal(('A'..'Z').to_a, sheet[0])
            assert_equal ['1'] * 26, sheet[1]
            assert_equal ['2'] * 26, sheet[2]
          end
        end
      end
    end
  end
end
