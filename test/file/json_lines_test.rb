require 'test_helper'
require 'ndr_import/file/json_lines'

module NdrImport
  module File
    # JSON Lines file handler tests
    class JsonLinesTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read JSON Lines file' do
        file_path = @permanent_test_files.join('hello_world.jsonl')
        handler = NdrImport::File::JsonLines.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal [{ 'text' => 'Hello world,' }, { 'text' => 'this is a jsonl document' }], sheet.to_a
        end
      end

      test 'should read JSON Lines file with UTF-8 encoding' do
        file_path = @permanent_test_files.join('hello_utf8.jsonl')
        handler = NdrImport::File::JsonLines.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal [{ 'text' => 'Hello world' }, { 'text' => 'This is a thorny þ issue!' }], lines
          assert(lines.all? { |hash| hash['text'].encoding.name == 'UTF-8' && hash['text'].valid_encoding? })
        end
      end

      test 'should read JSON Lines file with UTF-16 [BE] encoding' do
        file_path = @permanent_test_files.join('hello_utf16be.jsonl')
        handler = NdrImport::File::JsonLines.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal [{ 'text' => 'Hello world' }, { 'text' => 'This is a thorny þ issue!' }], lines
          assert(lines.all? { |hash| hash['text'].encoding.name == 'UTF-8' && hash['text'].valid_encoding? })
        end
      end

      test 'should read JSON Lines file with UTF-16 [LE] encoding' do
        file_path = @permanent_test_files.join('hello_utf16le.jsonl')
        handler = NdrImport::File::JsonLines.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal [{ 'text' => 'Hello world' }, { 'text' => 'This is a thorny þ issue!' }], lines
          assert(lines.all? { |hash| hash['text'].encoding.name == 'UTF-8' && hash['text'].valid_encoding? })
        end
      end

      test 'should read JSON Lines file with Windows-1252 encoding' do
        file_path = @permanent_test_files.join('hello_windows.jsonl')
        handler = NdrImport::File::JsonLines.new(file_path, nil)
        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet

          lines = sheet.to_a

          assert_equal [{ 'text' => 'Hello windows world' }, { 'text' => 'This is a thorny þ issue!' }], lines
          assert(lines.all? { |hash| hash['text'].encoding.name == 'UTF-8' && hash['text'].valid_encoding? })
        end
      end

      test 'should raise exception on invalid JSON Lines file' do
        assert_raises RuntimeError do
          file_path = @permanent_test_files.join('hello_world.pdf')
          handler = NdrImport::File::JsonLines.new(file_path, nil)
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
