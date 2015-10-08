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
    end
  end
end
