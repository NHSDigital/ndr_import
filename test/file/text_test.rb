require 'test_helper'
require 'ndr_import/file/text'

module NdrImport
  module File
    # Text file handler tests
    class TextTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read text file' do
        file_path = @permanent_test_files.join('hello_world.txt')
        handler = NdrImport::File::Text.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal ['Hello world,', 'this is a text document'], sheet.to_a
        end
      end

      test 'should raise exception on invalid text file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('hello_world.pdf')
          handler = NdrImport::File::Text.new(file_path, nil)
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
