# encoding: UTF-8
require 'test_helper'

# This tests the README page example
class ReadmeTest < ActiveSupport::TestCase
  test 'readme example' do
    require 'ndr_import/non_tabular/table'
    require 'ndr_import/file/registry'

    unzip_path = SafePath.new('test_space_rw')
    source_file = SafePath.new('permanent_test_files').join('flat_file.pdf')
    options = { 'unzip_path' => unzip_path }

    table = NdrImport::NonTabular::Table.new(
      'start_in_a_record' => false,
      'end_in_a_record' => false,
      'klass' => 'SomeTestKlass',
      'start_line_pattern' => /\A------\z/,
      'remove_lines' => { 'footer' => [/\A== Page \d+ of \d+ ==\z/i] },
      'columns' => [
        {
          'column' => 'one',
          'non_tabular_cell' => { 'lines' => Range.new(0, -1, true), 'capture' => /^(.*)$/i }
        }
      ]
    )

    # Use the Registry to enumerate over the files and their tables
    files = NdrImport::File::Registry.files(source_file, options)
    files.each do |filename|
      tables = NdrImport::File::Registry.tables(filename, nil, nil, options)
      tables.each do |_tablename, table_content|
        # Use the NonTabular::Table to tabulate the "table" contents
        table.transform(table_content).each do |_klass, _fields, _index|
          # Your code goes here
        end

        # Now we test the example
        results = []
        table.transform(table_content).each do |_klass, fields, _index|
          results << fields[:rawtext]['one']
        end
        assert table.is_a?(NdrImport::NonTabular::Table)
        assert_equal 4, results.count
        assert results.first.start_with?('1')
        assert results.last.start_with?('4')
        assert results.any? { |result| result =~ /This is captured/ }
        refute results.any? { |result| result =~ /This is never captured/ }
        refute results.any? { |result| result =~ /== Page/ }
      end
    end
  end
end
