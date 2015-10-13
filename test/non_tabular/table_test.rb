require 'test_helper'

# This tests the NdrImport::NonTabular::Table mapping class
class TableTest < ActiveSupport::TestCase
  def test_all_valid_options
    valid_options = %w(
      canonical_name capture_start_line columns end_line_pattern filename_pattern footer_lines
      format header_lines klass remove_lines start_line_pattern
    )
    assert_equal valid_options.sort,
                 NdrImport::NonTabular::Table.all_valid_options.sort
  end

  def test_should_raise_error_with_no_start_line_pattern
    assert_raise NdrImport::MappingError do
      NdrImport::NonTabular::Table.new(
        'columns' => [{ 'column' => 'one' }]
      )
    end

    assert_raise NdrImport::MappingError do
      NdrImport::NonTabular::Table.new(
        'start_line_pattern' => nil,
        'columns' => [{ 'column' => 'one' }]
      )
    end
  end

  def test_should_initialize_with_non_tabular_row
    table = NdrImport::NonTabular::Table.new(
      'start_line_pattern' => /\A-*\z/,
      'columns' => [{ 'column' => 'one' }]
    )
    assert_equal(/\A-*\z/, table.start_line_pattern)
  end

  test 'should test flat_file.txt' do
    table = YAML.load_file(SafePath.new('permanent_test_files').join('flat_file.yml'))
    assert table.is_a?(NdrImport::NonTabular::Table)
    filename = SafePath.new('permanent_test_files').join('flat_file.txt')
    enum = table.transform(File.new(filename).each)
    # puts enum.to_a.inspect

    results = []
    enum.each do |_klass, fields, _index|
      results << fields[:rawtext]['one']
    end

    assert_equal 4, results.count
    assert results.first.start_with?('1')
    assert results.last.start_with?('4')

    assert results.any? { |result| result =~ /This is captured/ }
    refute results.any? { |result| result =~ /This is never captured/ }
    refute results.any? { |result| result =~ /== Page/ }
  end

  def test_should_capture
    table = YAML.load <<YML
--- !ruby/object:NdrImport::NonTabular::Table
start_line_pattern: !ruby/regexp /^-{6}$/
header_lines: 1
footer_lines: 1
klass: SomeTestKlass
columns:
- standard_mapping: nhsnumber
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /^(\\d*)$/i
- column: address
  non_tabular_cell:
    lines: !ruby/range
      begin: 1
      end: 5
      excl: false
    capture: !ruby/regexp /^.{50}(.*)$/i
    join: ", "
- standard_mapping: postcode
  non_tabular_cell:
    lines: 6
    capture: !ruby/regexp /^.{50}(.*)$/i
- column: capture_inclusive
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /^CAPTURE INCLUSIVE$/
      end: !ruby/regexp /^Capture me.$/i
      excl: false
    capture: !ruby/regexp /^(.*)$/i
    join: "\\n"
- column: capture_exclusive
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /^CAPTURE EXCLUSIVE$/
      end: !ruby/regexp /^Do NOT capture me.$/i
      excl: true
    capture: !ruby/regexp /^(.*)$/i
    join: "\\n"
- column: capture_to_end
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /^CAPTURE TO END$/
      end: -1
      excl: false
    capture: !ruby/regexp /^(.*)$/i
    join: "\\n"
YML
    capture_example = <<-STR
This is never captured
------
1111111111
<----------------- 50 characters ---------------->Unit C, Magog Court
                                                  Shelford Bottom
                                                  Hinton Way
                                                  Cambridge

                                                  CB22 3AD

CAPTURE INCLUSIVE
Lorem ipsum dolor sit amet,
consectetur adipisicing elit,
Capture me.

CAPTURE EXCLUSIVE
Ut enim ad minim veniam, quis nostrud exercitation.
Do NOT capture me.

CAPTURE TO END
Lorem ipsum dolor sit amet, consectetur adipisicing elit.
Ut enim ad minim veniam, quis nostrud exercitation ullamco.
Duis aute irure dolor in reprehenderit in voluptate velit.
Excepteur sint occaecat cupidatat non proident, sunt in culpa.
------
This is never captured
STR
    enum = table.transform(capture_example.split(/\n/).map)
    assert_instance_of Enumerator, enum

    output = []
    enum.each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      [
        'SomeTestKlass', {
          'nhsnumber' => '1111111111',
          'postcode' => 'CB223AD',
          :rawtext => {
            'nhsnumber' => '1111111111',
            'address' => 'Unit C, Magog Court, Shelford Bottom, Hinton Way, Cambridge',
            'postcode' => 'CB22 3AD',
            'capture_inclusive' => "CAPTURE INCLUSIVE\nLorem ipsum dolor sit amet,\n" \
                                   "consectetur adipisicing elit,\nCapture me.",
            'capture_exclusive' => "CAPTURE EXCLUSIVE\n" \
                                   'Ut enim ad minim veniam, quis nostrud exercitation.',
            'capture_to_end' => "CAPTURE TO END\n" \
                                "Lorem ipsum dolor sit amet, consectetur adipisicing elit.\n" \
                                "Ut enim ad minim veniam, quis nostrud exercitation ullamco.\n" \
                                "Duis aute irure dolor in reprehenderit in voluptate velit.\n" \
                                'Excepteur sint occaecat cupidatat non proident, sunt in culpa.'
          }
        },
        1
      ]
    ]
    assert_equal expected_output.sort, output.sort
    assert_equal 25, table.non_tabular_lines.last.absolute_line_number
  end
end
