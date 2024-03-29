require 'test_helper'

# Test non tabular mapper class that expose private method(s) for testing
class NonTabularTestMapper
  # include NdrImport::Mapper
  include NdrImport::NonTabularFileHelper

  attr_accessor :mappings

  public :read_non_tabular_string
end

# This tests the NonTabularFileHelper class
class NonTabularFileHelperTest < ActiveSupport::TestCase
  simple_divider_example = <<-STR
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

  test 'should raise error with no non_tabular_row' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should raise error with no non_tabular_row start_line_pattern' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern:
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should raise error with no column non_tabular_cell' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should raise error with no column non_tabular_cell lines' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
      columns:
      - column: one
        non_tabular_cell:
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
      columns:
      - column: one
        non_tabular_cell:
          lines:
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should raise error with no column non_tabular_cell capture' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
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
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should only return two results with no start_in_a_record or end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(simple_divider_example)
    assert_equal 2, results.count
    assert results.first[0].start_with?('222')
    assert results.last[0].start_with?('333')
  end

  test 'should return three results with start_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
        start_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(simple_divider_example)
    assert_equal 3, results.count
    assert results.first[0].start_with?('111')
    assert results.last[0].start_with?('333')
  end

  test 'should return three results with end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(simple_divider_example)
    assert_equal 3, results.count
    assert results.first[0].start_with?('222')
    assert results.last[0].start_with?('444')
  end

  test 'should return four results with start_in_a_record and end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
        start_in_a_record: true
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(simple_divider_example)
    assert_equal 4, results.count
    assert results.first[0].start_with?('111')
    assert results.last[0].start_with?('444')
  end

  no_divider_example = <<-STR
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt.
STR

  test 'should return one results with start_in_a_record and end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
        start_in_a_record: true
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(no_divider_example)
    assert_equal 1, results.count
    assert results.first[0].start_with?('111')
  end

  simple_start_and_end_divider_example = <<-STR
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

  test 'should return four results with start and end dividers' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^----- START -----$/
        end_line_pattern: !ruby/regexp /^------ END ------$/
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: false
          capture: !ruby/regexp /^(.*)$/i
    YML
    results = mapper.read_non_tabular_string(simple_start_and_end_divider_example)
    assert_equal 4, results.count
    assert results.first[0].start_with?('111')
    assert results.last[0].start_with?('444')

    assert results.flatten.any? { |result| result =~ /This is captured/ }
    refute results.flatten.any? { |result| result =~ /This is never captured/ }
  end

  test 'documentation example' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^D\\|/
        capture_start_line: true
        end_in_a_record: true
      columns:
      - standard_mapping: nhsnumber
        non_tabular_cell:
          lines: 0
          capture:
          - !ruby/regexp /^D\\|([^|]*).*/
      - column: fulltextreport
        non_tabular_cell:
          lines: !ruby/range
            begin: 1
            end: -1
            excl: false
          capture: !ruby/regexp /^(?:R|\\d+)\\|(.*)$/i
          join: "\\n"
    YML
    documentation_example = [
      'D|1111111111|...',
      'R|This is a',
      '1|multiline report'
    ].join("\n")

    results = mapper.read_non_tabular_string(documentation_example)
    assert_equal 1, results.count
    result = results.first
    assert_equal '1111111111', result[0]
    assert_equal "This is a\nmultiline report", result[1]
  end

  test 'should capture' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^-{6}$/
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
    results = mapper.read_non_tabular_string(capture_example)
    assert_equal 1, results.count
    result = results.first
    assert_equal '1111111111', result[0]
    assert_equal 'Unit C, Magog Court, Shelford Bottom, Hinton Way, Cambridge', result[1]
    assert_equal 'CB22 3AD', result[2]
    assert_equal "CAPTURE INCLUSIVE\nLorem ipsum dolor sit amet,\n" \
                 "consectetur adipisicing elit,\nCapture me.",
                 result[3]
    assert_equal "CAPTURE EXCLUSIVE\nUt enim ad minim veniam, quis nostrud exercitation.",
                 result[4]
    assert_equal "CAPTURE TO END\n" \
                 "Lorem ipsum dolor sit amet, consectetur adipisicing elit.\n" \
                 "Ut enim ad minim veniam, quis nostrud exercitation ullamco.\n" \
                 "Duis aute irure dolor in reprehenderit in voluptate velit.\n" \
                 'Excepteur sint occaecat cupidatat non proident, sunt in culpa.',
                 result[5]

    assert_equal 25, mapper.non_tabular_lines.last.absolute_line_number
  end

  test 'handles non utf8 characters' do
    mixed_encoding_example = <<~STR
      111
      Lorem ipsum dolor sit amet.
      ------
      111
      Lorem ipsum dolor#{0xBE.chr} sit amet.
      ------
      111
      Lorem ipsum dolor sit amet.
      ------
    STR

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^111$/
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: true
          capture: !ruby/regexp /^(.*)$/i
    YML

    results = mapper.read_non_tabular_string(mixed_encoding_example)

    assert_equal 3, results.count, 'records were lost'

    assert_equal [27, 28, 27], results.map { |row| row.first.chars.to_a.length }
    assert_equal [27, 29, 27], results.map { |row| row.first.bytes.to_a.length }

    results.each do |row|
      assert row.first.valid_encoding?
      assert_equal Encoding.find('UTF-8'), row.first.encoding
    end
  end

  test 'should not allow junk bytes' do
    junk = <<~STR
      111
      Lorem ipsum dolor sit amet.
      ------
      111
      Lorem ipsum dolor#{0x8D.chr} sit amet.
      ------
      111
      Lorem ipsum dolor sit amet.
      ------
STR

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /^111$/
        end_in_a_record: true
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
      mapper.read_non_tabular_string(junk)
    end
  end

  test 'should conditionally preserve blank lines when joining non tabular data' do
    text = <<-STR.strip_heredoc
      111
      hello

      world
      ------
      111
      hello
      world
      ------
    STR

    preserve_blanks_mapper = NonTabularTestMapper.new
    preserve_blanks_mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /\\A111\\z/
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: true
          capture: !ruby/regexp /^(.*)$/i
          join: "\\n"
          preserve_blank_lines: true
    YML

    mapped_values = preserve_blanks_mapper.read_non_tabular_string(text)
    assert_equal ['hello', '', 'world'], mapped_values.first.first.split("\n")
    assert_equal %w[hello world], mapped_values.last.first.split("\n")

    mapper = NonTabularTestMapper.new
    mapper.mappings = load_esourcemapping_yaml(<<~YML)
      non_tabular_row:
        start_line_pattern: !ruby/regexp /\\A111\\z/
        end_in_a_record: true
      columns:
      - column: one
        non_tabular_cell:
          lines: !ruby/range
            begin: 0
            end: -1
            excl: true
          capture: !ruby/regexp /^(.*)$/i
          join: "\\n"
    YML

    mapped_values = mapper.read_non_tabular_string(text)
    assert_equal %w[hello world], mapped_values.first.first.split("\n")
    assert_equal %w[hello world], mapped_values.last.first.split("\n")
  end
end
