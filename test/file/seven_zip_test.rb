require 'test_helper'
require 'ndr_import/file/seven_zip'

module NdrImport
  module File
    # 7zip file handler tests
    class SevenZipTestTest < ActiveSupport::TestCase
      def setup
        @home = SafePath.new('test_space_rw')
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should reject non SafePath arguments' do
        file_path = @home.join('imaginary.7z')

        assert_raises ArgumentError do
          NdrImport::File::SevenZip.new(file_path.to_s, nil, 'unzip_path' => @home.to_s)
        end

        assert_raises ArgumentError do
          NdrImport::File::SevenZip.new(file_path.to_s, nil, 'unzip_path' => @home)
        end

        assert_raises ArgumentError do
          NdrImport::File::SevenZip.new(file_path, nil, 'unzip_path' => @home.to_s)
        end
      end

      test 'should read 7zip file with correct password' do
        options = { 'password' => 'FortuneCookie', 'unzip_path' => @home }
        file_path = @permanent_test_files.join('normal.7z')

        handler = NdrImport::File::SevenZip.new(file_path, nil, options)
        handler.files.all? do |filename|
          assert_instance_of SafePath, filename
        end
        files = handler.files.to_a
        assert_equal 'normal_pipe.csv', ::File.basename(files[0])
        assert_equal 'normal_thorn.csv', ::File.basename(files[1])

        exception = assert_raises RuntimeError do
          handler.tables
        end
        assert_equal 'SevenZip#tables should never be called', exception.message
      end

      test 'should not read 7zip file with incorrect password' do
        options = { 'password' => 'WrongPassword', 'unzip_path' => @home }
        file_path = @permanent_test_files.join('normal.7z')

        handler = NdrImport::File::SevenZip.new(file_path, nil, options)

        assert_raises SevenZipRuby::InvalidArchive do
          handler.files.to_a
        end
      end
    end
  end
end
