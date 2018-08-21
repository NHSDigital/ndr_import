# encoding: UTF-8
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
        handler = NdrImport::File::Text.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal ['Hello world,', 'this is a text document'], sheet.to_a
        end
      end

      test 'should read text file with UTF-8 encoding' do
        file_path = @permanent_test_files.join('hello_utf8.txt')
        handler = NdrImport::File::Text.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal ['Hello world', 'This is a thorny þ issue!'], lines
          assert lines.all? { |line| line.encoding.name == 'UTF-8' && line.valid_encoding? }
        end
      end

      test 'should read text file with UTF-16 [BE] encoding' do
        file_path = @permanent_test_files.join('hello_utf16be.txt')
        handler = NdrImport::File::Text.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal ['Hello world', 'This is a thorny þ issue!'], lines
          assert lines.all? { |line| line.encoding.name == 'UTF-8' && line.valid_encoding? }
        end
      end

      test 'should read text file with UTF-16 [LE] encoding' do
        file_path = @permanent_test_files.join('hello_utf16le.txt')
        handler = NdrImport::File::Text.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal ['Hello world', 'This is a thorny þ issue!'], lines
          assert lines.all? { |line| line.encoding.name == 'UTF-8' && line.valid_encoding? }
        end
      end

      test 'should read text file with Windows-1252 encoding' do
        file_path = @permanent_test_files.join('hello_windows.txt')
        handler = NdrImport::File::Text.new(file_path, nil, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal ['Hello windows world', 'This is a thorny þ issue!'], lines
          assert lines.all? { |line| line.encoding.name == 'UTF-8' && line.valid_encoding? }
        end
      end

      test 'should raise exception on invalid text file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('hello_world.pdf')
          handler = NdrImport::File::Text.new(file_path, nil, nil)
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
