require 'test_helper'
require 'ndr_import/file/docx'

module NdrImport
  module File
    # Word .docx document file handler tests
    class DocxTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read word file' do
        file_path = @permanent_test_files.join('hello_world.docx')
        handler = NdrImport::File::Docx.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal [
            'Hello world, this is a modern word document',
            'With more than one line of text',
            'Three in fact'
          ], sheet.to_a
        end
      end

      test 'should read password protected word file' do
        file_path = @permanent_test_files.join('password_protected_hello_world.docx')
        handler = NdrImport::File::Docx.new(file_path, nil, file_password: 'salad')
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal [
            'Hello world, this is a modern word document',
            'With more than one line of text',
            'Three in fact'
          ], sheet.to_a
        end
      end

      test 'should raise exception on invalid word file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('not_a_word_file.docx')
          handler = NdrImport::File::Docx.new(file_path, nil)
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
