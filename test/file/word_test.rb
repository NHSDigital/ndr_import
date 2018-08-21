require 'test_helper'
require 'ndr_import/file/pdf'

module NdrImport
  module File
    # Word document file handler tests
    class WordTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read word file' do
        file_path = @permanent_test_files.join('hello_world.doc')
        handler = NdrImport::File::Word.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal ['Hello world, this is a word document'], sheet.to_a
        end
      end

      test 'should raise exception on invalid word file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('not_a_word_file.doc')
          handler = NdrImport::File::Word.new(file_path, nil, nil)
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
