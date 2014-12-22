require 'test_helper'
require 'ndr_import/helpers/file/zip'
require 'zip/zipfilesystem'

# Zip file helper tests
class ZipTest < ActiveSupport::TestCase
  # This is a test importer class to test the Zip file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Zip
  end

  def setup
    @home = SafePath.new('test_space_rw')
    @permanent_test_files = SafePath.new('permanent_test_files')
    @importer  = TestImporter.new
  end

  test '.unzip should reject non SafePath arguments' do
    zip = @home.join('imaginary.zip')

    assert_raises ArgumentError do
      @importer.send(:unzip_file, zip.to_s, @home.to_s)
    end

    assert_raises ArgumentError do
      @importer.send(:unzip_file, zip.to_s, @home)
    end

    assert_raises ArgumentError do
      @importer.send(:unzip_file, zip, @home.to_s)
    end
  end

  test '.unzip unzip zip file' do
    zip_name = @home.join('test.zip')

    files = [
      @home.join('f1'),
      @home.join('f2'),
      @home.join('f3')
    ]

    files.each do |fname|
      File.open(fname, 'w') { |f| f.write "test #{fname}" }
    end

    ::Zip::ZipFile.open(zip_name, Zip::ZipFile::CREATE) do |zipfile|
      files.each do |fname|
        zipfile.add(File.basename(fname.to_s), fname.to_s)
      end
    end

    File.delete(*files)

    files.each do |fname|
      assert !File.exist?(fname)
    end

    assert File.exist?(zip_name)
    dest = @home.join('unziped')

    @importer.send(:unzip_file, zip_name, dest)

    files.each do |fname|
      assert File.exist?(dest.join(File.basename(fname)))
    end

    files.each do |fname|
      File.delete(dest.join(File.basename(fname)))
    end

    File.delete(zip_name)
    FileUtils.rm_r(dest)
  end
end
