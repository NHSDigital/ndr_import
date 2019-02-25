require 'test_helper'

# This tests the NdrImport::NonTabular::Table mapping class
class TableTest < ActiveSupport::TestCase
  def setup
    @simple_divider_example = <<-STR.split(/\n/).map
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt.
------
222
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo.
------
333
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla.
------
444
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim.
STR

    @no_divider_example = <<-STR.split(/\n/).map
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt.
STR

    @simple_start_and_end_divider_example = <<-STR.split(/\n/).map
----- START -----
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt.
------ END ------
This is never captured
----- START -----
222
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo.
------ END ------
This is never captured
----- START -----
333
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla.
------ END ------
This is never captured
----- START -----
444
This is captured
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim.
------ END ------
STR
  end

  def test_all_valid_options
    valid_options = %w[
      canonical_name capture_end_line capture_start_line columns end_in_a_record end_line_pattern
      filename_pattern format klass remove_lines row_identifier start_in_a_record start_line_pattern
    ]
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

  def test_should_test_flat_file_txt
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

  def test_should_raise_error_with_no_column_non_tabular_cell
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      table.transform(@simple_divider_example).to_a
    end
  end

  def test_should_raise_error_with_no_column_non_tabular_cell_lines
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
    YML
    assert_raise NdrImport::MappingError do
      table.transform(@simple_divider_example).to_a
    end

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines:
    YML
    assert_raise NdrImport::MappingError do
      table.transform(@simple_divider_example).to_a
    end
  end

  def test_should_raise_error_with_no_column_non_tabular_cell_capture
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
    YML
    assert_raise NdrImport::MappingError do
      table.transform(@simple_divider_example).to_a
    end

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture:
    YML
    assert_raise NdrImport::MappingError do
      table.transform(@simple_divider_example).to_a
    end
  end

  def test_should_only_return_two_results_with_no_start_in_a_record_or_end_in_a_record
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@simple_divider_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 2, results.count
    assert results.first.start_with?('222')
    assert results.last.start_with?('333')
  end

  def test_should_return_three_results_with_start_in_a_record
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      start_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@simple_divider_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 3, results.count
    assert results.first.start_with?('111')
    assert results.last.start_with?('333')
  end

  def test_should_return_three_results_with_end_in_a_record
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@simple_divider_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 3, results.count
    assert results.first.start_with?('222')
    assert results.last.start_with?('444')
  end

  def test_should_return_four_results_with_start_in_a_record_and_end_in_a_record
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      start_in_a_record: true
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@simple_divider_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 4, results.count
    assert results.first.start_with?('111')
    assert results.last.start_with?('444')
  end

  def test_should_return_one_results_with_start_in_a_record_and_end_in_a_record
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
      start_in_a_record: true
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@no_divider_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 1, results.count
    assert results.first.start_with?('111')
  end

  def test_should_return_four_results_with_start_and_end_dividers
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^----- START -----$/
      end_line_pattern: !ruby/regexp /^------ END ------$/
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    enum = table.transform(@simple_start_and_end_divider_example)
    assert_instance_of Enumerator, enum

    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 4, results.count
    assert results.first.start_with?('111')
    assert results.last.start_with?('444')

    assert results.any? { |result| result =~ /This is captured/ }
    refute results.any? { |result| result =~ /This is never captured/ }
  end

  def test_should_capture_end_line
    data = <<~STR.each_line
111
Lorem ipsum dolor sit amet.
CAPTURE THIS CODE ABC
111
Lorem ipsum dolor sit amet.
CAPTURE THIS CODE XYZ
111
Lorem ipsum dolor sit amet.
CAPTURE THIS CODE 123
STR

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /\\A111\\z/
      end_line_pattern: !ruby/regexp /\\ACAPTURE THIS CODE/
      capture_start_line: true
      capture_end_line: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: -1
          capture: !ruby/regexp /\\A(.*)\\z/i
    YML
    enum = table.transform(data)
    assert_instance_of Enumerator, enum

    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 3, results.count
    assert_equal 'CAPTURE THIS CODE ABC', results.first
  end

  def test_should_capture
    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^-{6}$/
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
        0
      ]
    ]
    assert_equal expected_output.sort, output.sort
    assert_equal 25, table.non_tabular_lines.last.absolute_line_number
  end

  def test_handles_non_utf8_characters
    mixed_encoding_example = <<-STR.each_line
111
Lorem ipsum dolor sit amet.
------
111
Lorem ipsum dolor\xBE sit amet.
------
111
Lorem ipsum dolor sit amet.
------
STR

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^111$/
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: true
          capture: !ruby/regexp /^(.*)$/i
    YML

    enum = table.transform(mixed_encoding_example)
    assert_instance_of Enumerator, enum
    results = enum.map { |_klass, fields, _index| fields[:rawtext]['one'] }

    assert_equal 3, results.count, 'records were lost'

    assert_equal [27, 28, 27], results.map { |row| row.chars.to_a.length }
    assert_equal [27, 29, 27], results.map { |row| row.bytes.to_a.length }

    results.each do |row|
      assert row.first.valid_encoding?
      assert_equal Encoding.find('UTF-8'), row.first.encoding
    end
  end

  def test_should_not_allow_junk_bytes
    junk = <<-STR.each_line
111
Lorem ipsum dolor sit amet.
------
111
Lorem ipsum dolor\x8D sit amet.
------
111
Lorem ipsum dolor sit amet.
------
STR

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^111$/
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: true
          capture: !ruby/regexp /^(.*)$/i
    YML

    assert_raises(UTF8Encoding::UTF8CoercionError) do
      table.transform(junk).to_a
    end
  end

  def test_should_strip_captured_rawtext
    unwanted_white_space = <<-STR.each_line
111
Trailing whitespace        end_of_line
------
111
        Leading whitespaceend_of_line
------
111
        Leading and trailing whitespace        end_of_line
------
111
Should not match this
------
STR

    table = YAML.load <<-YML.strip_heredoc
      --- !ruby/object:NdrImport::NonTabular::Table
      start_line_pattern: !ruby/regexp /^111$/
      end_in_a_record: true
      klass: SomeTestKlass
      columns:
      - column: one
        non_tabular_cell:
          lines: 0
          capture: !ruby/regexp /^(.*)end_of_line$/i
          trim_rawtext: left
    YML

    enum = table.transform(unwanted_white_space)
    assert_instance_of Enumerator, enum

    output = []
    enum.each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_rawtext_ouput = [{ 'one' => 'Trailing whitespace' },
                              { 'one' => 'Leading whitespace' },
                              { 'one' => 'Leading and trailing whitespace' },
                              { 'one' => '' }]
    assert_equal expected_rawtext_ouput, (output.map { |row| row[1][:rawtext] })
  end
end
