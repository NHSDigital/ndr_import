# encoding: UTF-8

require 'test_helper'

# Test non tabular mapper class that expose private method(s) for testing
class NonTabularTestMapper
  # include NdrImport::Mapper
  include NdrImport::NonTabularFileHelper

  attr_accessor :mappings

  public :read_non_tabular_string
end

class NonTabularFileHelperTest < ActiveSupport::TestCase
  simple_divider_example = <<-STR
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
------
222
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
------
333
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
------
444
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
STR

  test 'should raise error with no non_tabular_row' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end
  end

  test 'should raise error with no non_tabular_row start_line_pattern' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
      non_tabular_row:
      columns:
      - column: one
    YML
    assert_raise NdrImport::MappingError do
      mapper.read_non_tabular_string(simple_divider_example)
    end

    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(simple_divider_example)
      assert_equal 2, results.count
      assert results.first[0].start_with?('222')
      assert results.last[0].start_with?('333')
    end
  end

  test 'should return three results with start_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(simple_divider_example)
      assert_equal 3, results.count
      assert results.first[0].start_with?('111')
      assert results.last[0].start_with?('333')
    end
  end

  test 'should return three results with end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(simple_divider_example)
      assert_equal 3, results.count
      assert results.first[0].start_with?('222')
      assert results.last[0].start_with?('444')
    end
  end

  test 'should return four results with start_in_a_record and end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(simple_divider_example)
      assert_equal 4, results.count
      assert results.first[0].start_with?('111')
      assert results.last[0].start_with?('444')
    end
  end

  no_divider_example = <<-STR
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
STR

  test 'should return one results with start_in_a_record and end_in_a_record' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(no_divider_example)
      assert_equal 1, results.count
      assert results.first[0].start_with?('111')
    end
  end

  simple_start_and_end_divider_example = <<-STR
----- START -----
111
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
------ END ------
This is never captured
----- START -----
222
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
------ END ------
This is never captured
----- START -----
333
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
------ END ------
This is never captured
----- START -----
444
This is captured
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
------ END ------
STR

  test 'should return four results with start and end dividers' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    assert_nothing_raised do
      results = mapper.read_non_tabular_string(simple_start_and_end_divider_example)
      assert_equal 4, results.count
      assert results.first[0].start_with?('111')
      assert results.last[0].start_with?('444')

      assert results.flatten.any? { |result| result =~ /This is captured/ }
      deny results.flatten.any? { |result| result =~ /This is never captured/ }
    end
  end

  test 'documentation example' do
    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    mapper.mappings = YAML.load <<-YML
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
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
------
This is never captured
STR
    # assert_nothing_raised do
      results = mapper.read_non_tabular_string(capture_example)
      assert_equal 1, results.count
      result = results.first
      assert_equal '1111111111', result[0]
      assert_equal 'Unit C, Magog Court, Shelford Bottom, Hinton Way, Cambridge', result[1]
      assert_equal 'CB22 3AD', result[2]
      assert_equal "CAPTURE INCLUSIVE\nLorem ipsum dolor sit amet,\nconsectetur adipisicing elit,\nCapture me.",
                   result[3]
      assert_equal "CAPTURE EXCLUSIVE\nUt enim ad minim veniam, quis nostrud exercitation.",
                   result[4]
      # puts result.inspect
      # flunk ''
    # end
  end

  test 'handles non utf8 characters' do
    mixed_encoding_example = <<-STR
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

    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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
    junk = <<-STR
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

    mapper = NonTabularTestMapper.new
    mapper.mappings = YAML.load <<-YML
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

end
