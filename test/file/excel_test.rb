require 'test_helper'
require 'ndr_import/file/excel'

module NdrImport
  module File
    # Excel file handler tests
    class ExcelTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read xls file' do
        file_path = @permanent_test_files.join('sample_xls.xls')
        handler = NdrImport::File::Excel.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_equal 'Sheet1', tablename
          assert_instance_of Enumerator, sheet
          assert_equal %w(1A 1B), sheet.first
        end
      end

      test 'should read xlsx file' do
        file_path = @permanent_test_files.join('sample_xlsx.xlsx')
        handler = NdrImport::File::Excel.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_equal 'Sheet1', tablename
          assert_instance_of Enumerator, sheet
          assert_equal %w(1A 1B), sheet.first
        end
      end

      test 'should read xlsm file' do
        file_path = @permanent_test_files.join('sample_xlsm.xlsm')
        handler = NdrImport::File::Excel.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_equal 'Sheet1', tablename
          assert_instance_of Enumerator, sheet
          assert_equal %w[1A 1B], sheet.first
        end
      end

      test 'should read xlsx file with null sheet' do
        file_path = @permanent_test_files.join('blank_tab_test.xlsx')
        handler   = NdrImport::File::Excel.new(file_path, nil)

        sheets = handler.tables.map { |_tablename, sheet| sheet }

        assert_equal %w(column_a column_b column_c column_d), sheets[0].next
        assert_equal %w(11111 ABC123 8888888888 2), sheets[0].next
        assert_equal %w(column_a column_b column_c column_d), sheets[1].next
        assert_equal %w(11111 ABC123 8888888888 3), sheets[1].next
        assert_raises(StopIteration) { sheets[2].next }
      end

      %w(sheet_streaming.xlsx sheet_streaming.xls).each do |filename|
        test "should be able to stream from multiple sheets at once from #{filename}" do
          file_path = @permanent_test_files.join(filename)
          handler   = NdrImport::File::Excel.new(file_path, nil)

          sheets = handler.tables.map { |_tablename, sheet| sheet }

          assert_equal %w(1A1 1B1), sheets[0].next
          assert_raises(StopIteration) { sheets[2].next }
          assert_equal %w(2A1 2B1), sheets[1].next
          assert_equal %w(2A2 2B2), sheets[1].next
          assert_equal %w(1A2 1B2), sheets[0].next
          assert_raises(StopIteration) { sheets[2].next }
        end
      end

      test 'should read xlsx file with the incorrect xls extension' do
        file_path = @permanent_test_files.join('xlsx_file_xls_extension.xls')
        handler = NdrImport::File::Excel.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_equal 'Sheet1', tablename
          assert_instance_of Enumerator, sheet
          assert_equal %w(1A 1B), sheet.first
        end

        SafeFile.delete @permanent_test_files.join('xlsx_file_xls_extension_amend.xlsx')
      end

      test 'should read password protected xlsx file' do
        file_path = @permanent_test_files.join('password_protected_sample_xlsx.xlsx')
        handler = NdrImport::File::Excel.new(file_path, nil, file_password: 'carrot')
        handler.tables.each do |tablename, sheet|
          assert_equal 'Sheet1', tablename
          assert_instance_of Enumerator, sheet
          assert_equal %w(1A 1B), sheet.first
        end
      end

      test 'read_excel_file helper should handle exceptions' do
        # txt file
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('flat_file.txt')
          handler = NdrImport::File::Excel.new(file_path, nil)

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end

        # .txt file in .xls extension
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('txt_file_xls_extension.xls')
          handler = NdrImport::File::Excel.new(file_path, 'txt')

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end

        # .txt file in .xlsx extension
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('txt_file_xlsx_extension.xlsx')
          handler = NdrImport::File::Excel.new(file_path, 'txt')

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end

        SafeFile.delete @permanent_test_files.join('txt_file_xls_extension_amend.xlsx')
      end

      test 'should declare that it does not handle IO streams' do
        refute NdrImport::File::Excel.can_stream_data?
      end
    end
  end
end
