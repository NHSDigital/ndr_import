require 'test_helper'
require 'ndr_import/helpers/file/pdf'

# PDF file helper tests
class PdfTest < ActiveSupport::TestCase
  # This is a test importer class to test the PDF file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Pdf

    def read_pdf_file_content(path)
      read_pdf_file(path)
    end
  end

  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
    @importer  = TestImporter.new
  end

  test 'read_pdf_file helper should read pdf file' do
    file_content = @importer.read_pdf_file_content(@permanent_test_files.join('hello_world.pdf'))
    assert_equal file_content, ['Hello World']
  end

  test 'read_pdf_file helper should raise exception on invalid pdf file' do
    assert_raised RuntimeError do
      @importer.read_pdf_file_content(@permanent_test_files.join('not_a_pdf.pdf'))
    end
  end
end
