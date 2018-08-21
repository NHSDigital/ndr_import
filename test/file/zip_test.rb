require 'test_helper'
require 'ndr_import/file/zip'
require 'zip'

module NdrImport
  module File
    # Zip file handler tests
    class ZipTest < ActiveSupport::TestCase
      def setup
        @home = SafePath.new('test_space_rw')
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should reject non SafePath arguments' do
        file_path = @home.join('imaginary.zip')

        assert_raises ArgumentError do
          NdrImport::File::Zip.new(file_path.to_s, nil, nil, 'unzip_path' => @home.to_s)
        end

        assert_raises ArgumentError do
          NdrImport::File::Zip.new(file_path.to_s, nil, nil, 'unzip_path' => @home)
        end

        assert_raises ArgumentError do
          NdrImport::File::Zip.new(file_path, nil, nil, 'unzip_path' => @home.to_s)
        end
      end

      test 'should read table correctly' do
        options = { 'unzip_path' => @home }
        file_path = @permanent_test_files.join('normal.csv.zip')

        handler = NdrImport::File::Zip.new(file_path, nil, nil, options)
        handler.files.each do |filename|
          assert_instance_of SafePath, filename
          assert_equal 'normal.csv', ::File.basename(filename)
        end

        exception = assert_raises RuntimeError do
          handler.tables
        end
        assert_equal 'Zip#tables should never be called', exception.message
      end
    end
  end
end
