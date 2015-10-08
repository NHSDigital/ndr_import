require 'test_helper'
require 'ndr_import/file/pdf'

module NdrImport
  module File
    # PDF file handler tests
    class PdfTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read pdf correctly' do
        file_path = @permanent_test_files.join('hello_world.pdf')
        handler = NdrImport::File::Pdf.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal ['Hello World'], sheet.to_a
        end
      end

      test 'should raise exception on invalid pdf file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('not_a_pdf.pdf')
          handler = NdrImport::File::Pdf.new(file_path, nil)
          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end
      end
    end
  end
end
