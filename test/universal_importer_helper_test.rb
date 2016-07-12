# encoding: UTF-8
require 'test_helper'
require 'ndr_import/universal_importer_helper'

# This tests the UniversalImporterHelper mixin
class UniversalImporterHelperTest < ActiveSupport::TestCase
  # This is a test importer class to test the excel file helper mixin
  class TestImporter
    include NdrImport::UniversalImporterHelper

    def initialize
      @table_mappings = [
        NdrImport::Table.new(:filename_pattern => /\.xls\z/i,
                             :tablename_pattern => /\Asheet1\z/i)
      ]
    end

    def get_notifier(_)
    end
  end

  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
    @test_importer = TestImporter.new
  end

  test 'extract with matching mapping' do
    source_file = @permanent_test_files.join('sample_xls.xls')
    unzip_path = SafePath.new('test_space_rw').to_s
    enumerator_ran = false
    @test_importer.extract(source_file, unzip_path) do |table, rows|
      assert_instance_of NdrImport::Table, table
      assert_instance_of Enumerator, rows
      enumerator_ran = true
    end
    assert enumerator_ran
  end

  test 'extract without matching mapping' do
    source_file = @permanent_test_files.join('sample_xlsx.xlsx')
    unzip_path = SafePath.new('test_space_rw').to_s
    enumerator_ran = false
    @test_importer.extract(source_file, unzip_path) do |_table, _rows|
      enumerator_ran = true
    end
    refute enumerator_ran
  end

  test 'get_notifier' do
    class TestImporterWithoutNotifier
      include NdrImport::UniversalImporterHelper
    end

    assert_raise(RuntimeError) do
      TestImporterWithoutNotifier.new.get_notifier(10_000)
    end
  end
end
