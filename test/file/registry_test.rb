require 'test_helper'
require 'ndr_import/file/registry'

module NdrImport
  module File
    # Registry file handler tests
    class RegistryTest < ActiveSupport::TestCase
      def setup
        @home = SafePath.new('test_space_rw')
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'Registry.handlers' do
        assert_instance_of Hash, NdrImport::File::Registry.handlers
        assert_equal %w[csv delimited doc pdf txt xls xlsx zip],
                     NdrImport::File::Registry.handlers.keys.sort
      end

      test 'should fail to enumerate unknown format' do
        exception = assert_raises(RuntimeError) do
          file_path = @permanent_test_files.join('normal.csv')
          tables = NdrImport::File::Registry.tables(file_path, 'mp3')
          tables.each do |tablename, sheet|
            assert_nil tablename
            sheet.to_a
          end
        end

        assert_equal 'Error: Unknown file format "mp3"', exception.message
      end

      test 'should enumerate pdf file table' do
        file_path = @permanent_test_files.join('hello_world.pdf')
        tables = NdrImport::File::Registry.tables(file_path, nil)
        tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal ['Hello World ', 'Goodbye Universe ', ' '], sheet.to_a
        end
      end

      test 'should enumerate zip file tables' do
        options = { 'unzip_path' => @home }
        file_path = @permanent_test_files.join('normal.csv.zip')
        files = NdrImport::File::Registry.files(file_path, options)
        files.each do |filename|
          tables = NdrImport::File::Registry.tables(filename, nil, options)

          tables.each do |tablename, sheet|
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
