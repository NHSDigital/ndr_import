require 'test_helper'

# This tests the NdrImport::Table mapping class
class TableTest < ActiveSupport::TestCase
  def test_deserialize_table
    table = simple_deserialized_table
    assert_instance_of NdrImport::Table, table
    assert_equal 2, table.header_lines
    assert_equal 1, table.footer_lines
    assert_equal 'pipe', table.format
    assert_equal 'SomeTestKlass', table.klass
    assert_equal 'somename', table.canonical_name
    assert_equal [{ 'column' => 'one' }, { 'column' => 'two' }, { 'column' => 'three' }],
                 table.columns
  end

  def test_initialize
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                 :format => 'pipe', :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])
    assert_instance_of NdrImport::Table, table
    assert_equal 2, table.header_lines
    assert_equal 1, table.footer_lines
    assert_equal 'pipe', table.format
    assert_equal 'SomeTestKlass', table.klass
    assert_equal [{ 'column' => 'one' }, { 'column' => 'two' }], table.columns
  end

  def test_should_raise_error_on_invalid_initialization
    # incorrect parameter type
    assert_raises ArgumentError do
      NdrImport::Table.new([])
    end
    # invalid option
    assert_raises ArgumentError do
      NdrImport::Table.new(:potato => true)
    end
  end

  def test_match_with_no_patterns
    table = NdrImport::Table.new
    assert table.match('example.csv', nil)
    assert table.match('example.xslx', 'Sheet1')
  end

  def test_match_with_only_filename_pattern
    table = NdrImport::Table.new(:filename_pattern => /\.(csv|xlsx)\z/i)
    assert table.match('example.csv', nil)
    assert table.match('example.xlsx', 'Sheet1')

    table = NdrImport::Table.new(:filename_pattern => /\Ademo\.(csv|xlsx)\z/i)
    refute table.match('example.csv', nil)
    refute table.match('example.xlsx', 'Sheet1')
  end

  def test_match_with_both_patterns
    table = NdrImport::Table.new(:filename_pattern => /\.xlsx\z/i,
                                 :tablename_pattern => /\Asheet1\z/i)
    assert table.match('example.xlsx', 'Sheet1')
    refute table.match('example.xlsx', 'Sheet2')
  end

  def test_transform
    lines = [%w(ONE TWO), %w(CARROT POTATO), %w(BACON SAUSAGE)].each
    table = NdrImport::Table.new(:header_lines => 1, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 1],
      ['SomeTestKlass', { :rawtext => { 'one' => 'BACON', 'two' => 'SAUSAGE' } }, 2]
    ]
    assert_equal expected_output, output
  end

  def test_process_line
    # No header row, process the first line
    table = NdrImport::Table.new(:header_lines => 0, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.process_line(%w(CARROT POTATO)).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 0]
    ]
    assert_equal expected_output.sort, output.sort

    # One header row, don't process the first line
    table = NdrImport::Table.new(:header_lines => 1, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.process_line(%w(ONE TWO)).each { |*stuff| output << stuff }
    table.process_line(%w(CARROT POTATO)).each { |*stuff| output << stuff }

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 1]
    ]
    assert_equal expected_output, output
  end

  def test_process_line_with_unsatisifed_header
    table = NdrImport::Table.new(:header_lines => 1, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    exception = assert_raises(RuntimeError) { table.process_line(%w(ONE THREE)).to_a }
    assert_equal 'Header is not valid! missing: ["two"] unexpected: ["three"]', exception.message
  end

  def test_transform_line
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                 :columns => column_level_klass_mapping)
    enum = table.transform_line(%w(CARROT POTATO PEA), 7)
    assert_instance_of Enumerator, enum

    output = []
    enum.each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 7],
      ['SomeOtherKlass', { :rawtext => { 'two' => 'POTATO', 'three' => 'PEA' } }, 7]
    ]
    assert_equal expected_output.sort, output.sort
  end

  def test_encode_with
    # encode_with(coder)
  end

  def test_skip_footer_lines
    table = simple_deserialized_table
    lines = (1..10).each
    assert_equal((1..7).to_a, table.send(:skip_footer_lines, lines, 3).to_a)
    assert_equal((1..10).to_a, table.send(:skip_footer_lines, lines, 0).to_a)
  end

  def test_masked_mappings
    # table level
    table = simple_deserialized_table
    table_level_klass_masked_mappings = {
      'SomeTestKlass' => [{ 'column' => 'one' }, { 'column' => 'two' }, { 'column' => 'three' }]
    }
    assert_equal table_level_klass_masked_mappings, table.send(:masked_mappings)

    # column level
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                 :columns => column_level_klass_mapping)

    assert_equal column_level_klass_masked_mappings, table.send(:masked_mappings)
  end

  def test_column_level_klass_masked_mappings
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                 :columns => column_level_klass_mapping)

    assert_equal column_level_klass_masked_mappings,
                 table.send(:column_level_klass_masked_mappings)
  end

  def test_ensure_mappings_define_klass
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1, :columns => [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two' }
    ])
    assert_raise(RuntimeError) { table.send(:ensure_mappings_define_klass) }

    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1, :columns => [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => 'SomeOtherKlass' }
    ])
    table.send(:ensure_mappings_define_klass)
  end

  def test_mask_mappings_by_klass
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                 :columns => column_level_klass_mapping)
    some_test_klass_mapping = [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
      { 'do_not_capture' => true }
    ]
    assert_equal some_test_klass_mapping,
                 table.send(:mask_mappings_by_klass, 'SomeTestKlass')

    some_other_klass_mapping = [
      { 'do_not_capture' => true },
      { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
      { 'column' => 'three', 'klass' => 'SomeOtherKlass' }
    ]
    assert_equal some_other_klass_mapping,
                 table.send(:mask_mappings_by_klass, 'SomeOtherKlass')
  end

  def test_valid_single_line_header
    lines = [
      %w(ONE TWO),
      %w(CARROT POTATO),
      %w(BACON SAUSAGE)
    ].each

    table = NdrImport::Table.new(:header_lines => 1, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 1],
      ['SomeTestKlass', { :rawtext => { 'one' => 'BACON', 'two' => 'SAUSAGE' } }, 2]
    ]
    assert table.header_valid?
    assert_equal expected_output, output
  end

  def test_valid_multi_line_header
    lines = [
      %w(NOTHEADING1 NOTHEADING2),
      %w(ONE TWO),
      %w(DEFINITELYNOTHEADING1 DEFINITELYNOTHEADING2),
      %w(CARROT POTATO),
      %w(BACON SAUSAGE)
    ].each

    table = NdrImport::Table.new(:header_lines => 3, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' } }, 3],
      ['SomeTestKlass', { :rawtext => { 'one' => 'BACON', 'two' => 'SAUSAGE' } }, 4]
    ]
    assert table.header_valid?
    assert_equal expected_output, output
  end

  def test_varying_header_line_lengths_with_valid_header_row
    lines = [
      %w(NOTHEADING1 NOTHEADING2 UHOH3 UHOH4),
      %w(ONE TWO),
      %w(DEFINITELYNOTHEADING1 DEFINITELYNOTHEADING2),
      %w(UNO DOS)
    ].each

    table = NdrImport::Table.new(:header_lines => 3, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    assert table.header_valid?

    expected_output = [['SomeTestKlass', { :rawtext => { 'one' => 'UNO', 'two' => 'DOS' } }, 3]]
    assert_equal expected_output, output
  end

  def test_varying_header_line_lengths_without_valid_header_row
    lines = [
      %w(NOTHEADING1 NOTHEADING2 UHOH3 UHOH4),
      %w(ONE TWO NOPE),
      %w(NOT_HERE OR_HERE),
      %w(UNO DOS)
    ].each

    table = NdrImport::Table.new(:header_lines => 3, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    exception = assert_raises(RuntimeError) { table.transform(lines).to_a }

    assert_match(/Header is not valid!/, exception.message)
    assert_match(/missing: \["one", "two"\]/, exception.message)
    assert_match(/unexpected: \["not_here", "or_here"\]/, exception.message)
  end

  def test_jumbled_header
    lines = [
      %w(NOTHEADING1 NOTHEADING2 NOTHEADING3),
      %w(ONE THREE TWO),
      %w(DATA ROW HERE)
    ].each

    table = NdrImport::Table.new(
      :header_lines => 2,
      :footer_lines => 0,
      :klass => 'SomeTestKlass',
      :columns => [
        { 'column' => 'one' },
        { 'column' => 'two' },
        { 'column' => 'three' }
      ]
    )

    exception = assert_raises(RuntimeError) { table.transform(lines).to_a }
    assert_equal('Header is not valid! (out of order)', exception.message)
  end

  def test_wrong_header_names
    lines = [
      %w(NOTHEADING1 NOTHEADING2 NOTHEADING3),
      %w(FUN TWO TREE),
      %w(DATA ROW HERE)
    ].each

    table = NdrImport::Table.new(
      :header_lines => 2,
      :footer_lines => 0,
      :klass => 'SomeTestKlass',
      :columns => [
        { 'column' => 'one' },
        { 'column' => 'two' },
        { 'column' => 'three' }
      ]
    )

    exception = assert_raises(RuntimeError) { table.transform(lines).to_a }
    assert_equal('Header is not valid! missing: ' \
                 '["one", "three"] unexpected: ["fun", "tree"]', exception.message)
  end

  private

  def simple_deserialized_table
    Psych.load <<YML
--- !ruby/object:NdrImport::Table
canonical_name: somename
# filename_pattern: !ruby/regexp //
header_lines: 2
footer_lines: 1
format: pipe
klass: SomeTestKlass
# non_tabular_row:
#   ...
columns:
- column: one
- column: two
- column: three
YML
  end

  def column_level_klass_mapping
    [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
      { 'column' => 'three', 'klass' => 'SomeOtherKlass' }
    ]
  end

  def column_level_klass_masked_mappings
    {
      'SomeTestKlass' => [
        { 'column' => 'one', 'klass' => 'SomeTestKlass' },
        { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
        { 'do_not_capture' => true }
      ],
      'SomeOtherKlass' => [
        { 'do_not_capture' => true },
        { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
        { 'column' => 'three', 'klass' => 'SomeOtherKlass' }
      ]
    }
  end
end
