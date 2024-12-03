require 'test_helper'

class TestNoCoderTable < NdrImport::NonTabular::Table
  undef_method :encode_with
end

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
    table = NdrImport::Table.new(header_lines: 2, file_password: 'leek', footer_lines: 1,
                                 format: 'pipe', klass: 'SomeTestKlass',
                                 columns: [{ 'column' => 'one' }, { 'column' => 'two' }])
    assert_instance_of NdrImport::Table, table
    assert_equal 2, table.header_lines
    assert_equal 1, table.footer_lines
    assert_equal 'pipe', table.format
    assert_equal 'SomeTestKlass', table.klass
    assert_equal 'leek', table.file_password
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

  test 'should convert last_data_column into an index' do
    table = NdrImport::Table.new(last_data_column: 3)
    assert_equal 2, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: 'F')
    assert_equal 5, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: 'AE')
    assert_equal 30, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: 'BE')
    assert_equal 56, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: 'ABN')
    assert_equal 741, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: 'abn')
    assert_equal 741, table.send(:last_column_to_transform)

    table = NdrImport::Table.new(last_data_column: nil)
    assert_equal(-1, table.send(:last_column_to_transform))

    table = NdrImport::Table.new(last_data_column: Date.new(2021, 1, 1))
    exception = assert_raises(RuntimeError) do
      table.send(:last_column_to_transform)
    end
    assert_equal "Unknown 'last_data_column' format: 2021-01-01 (Date)", exception.message
  end

  test 'should not transform data after the last_data_column' do
    lines = [%w[ONE TWO], %w[CARROT POTATO], %w[BACON SAUSAGE]]
    table = NdrImport::Table.new(header_lines: 1, footer_lines: 0,
                                 klass: 'SomeTestKlass',
                                 last_data_column: 1,
                                 columns: [{ 'column' => 'one' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { rawtext: { 'one' => 'CARROT' } }, 1],
      ['SomeTestKlass', { rawtext: { 'one' => 'BACON' } }, 2]
    ]
    assert_equal expected_output, output
  end

  test 'should raise an error if last_data_column is smaller than column mappings' do
    lines = [%w[ONE TWO], %w[CARROT POTATO], %w[BACON SAUSAGE]]
    table = NdrImport::Table.new(header_lines: 1, footer_lines: 0,
                                 klass: 'SomeTestKlass',
                                 last_data_column: 1,
                                 columns: [{ 'column' => 'one' }, { 'column' => 'two' }])

    exception = assert_raises(RuntimeError) do
      output = []
      table.transform(lines).each do |klass, fields, index|
        output << [klass, fields, index]
      end
    end

    assert_equal 'Header is not valid! missing: ["two"]', exception.message
  end

  test 'should raise an error if last_data_column is larger than column mappings' do
    lines = [%w[ONE TWO THREE], %w[CARROT POTATO CABBAGE], %w[BACON SAUSAGE BURGER]]
    table = NdrImport::Table.new(header_lines: 1, footer_lines: 0,
                                 klass: 'SomeTestKlass',
                                 last_data_column: 'C',
                                 columns: [{ 'column' => 'one' }, { 'column' => 'two' }])

    exception = assert_raises(RuntimeError) do
      output = []
      table.transform(lines).each do |klass, fields, index|
        output << [klass, fields, index]
      end
    end

    assert_equal 'Header is not valid! unexpected: ["three"]', exception.message
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

  def test_transform_line_row_identifier_index
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1, :row_identifier => :index,
                                 :columns => column_level_klass_mapping)
    enum = table.transform_line(%w(CARROT POTATO PEA), 7)
    assert_instance_of Enumerator, enum

    output = []
    enum.each do |klass, fields, index|
      output << [klass, fields, index]
    end

    expected_output = [
      ['SomeTestKlass', { :rawtext => { 'one' => 'CARROT', 'two' => 'POTATO' }, 'row_identifier' => 7 }, 7],
      ['SomeOtherKlass', { :rawtext => { 'two' => 'POTATO', 'three' => 'PEA' }, 'row_identifier' => 7 }, 7]
    ]
    assert_equal expected_output.sort, output.sort
  end

  def test_transform_line_row_identifier_uuid
    table = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1, :row_identifier => :uuid,
                                 :columns => column_level_klass_mapping)
    enum = table.transform_line(%w(CARROT POTATO PEA), 7)
    assert_instance_of Enumerator, enum

    output = []
    enum.each do |klass, fields, _index|
      output << [klass, fields['row_identifier']]
    end
    identifiers = output.map(&:last)

    assert_equal 2, identifiers.count
    assert_equal 2, identifiers.compact.count
    assert_equal 1, identifiers.uniq.count
    assert_equal 36, identifiers.first.length
  end

  def test_encode_with
    table = NdrImport::Table.new
    assert table.instance_variables.include?(:@row_index)
    refute table.class.all_valid_options.include?('row_index')
    assert_nil table.columns

    coder = {}
    table.encode_with(coder)
    assert coder.key?('columns')

    yaml_output = table.to_yaml
    assert yaml_output.include?('columns')
    refute yaml_output.include?('row_index')
    assert load_esourcemapping_yaml(yaml_output).is_a?(NdrImport::Table)
  end

  def test_encode_with_compare
    table_options = {
      columns: %w[a b],
      klass: 'SomeKlass',
      start_line_pattern: 'TODO',
      end_line_pattern: 'TODO'
    }
    no_coder_table = TestNoCoderTable.new(table_options)
    ndr_table = NdrImport::NonTabular::Table.new(table_options)

    assert no_coder_table.is_a?(NdrImport::Table)
    assert ndr_table.is_a?(NdrImport::Table)
    assert no_coder_table.is_a?(NdrImport::NonTabular::Table)
    assert ndr_table.is_a?(NdrImport::NonTabular::Table)

    refute no_coder_table.respond_to?(:encode_with)
    assert ndr_table.respond_to?(:encode_with)

    no_coder_table_yaml_order = get_yaml_mapping_order(no_coder_table.to_yaml)
    ndr_table_yaml_order = get_yaml_mapping_order(ndr_table.to_yaml)

    # no_coder_table_yaml_order => ["klass", "columns", "start_line_pattern", "end_line_pattern", "row_index"]
    # ndr_table_yaml_order => ["klass", "start_line_pattern", "end_line_pattern", "columns"]

    assert no_coder_table_yaml_order.include?('row_index')
    refute ndr_table_yaml_order.include?('row_index')

    refute no_coder_table_yaml_order.last == 'columns'
    assert ndr_table_yaml_order.last == 'columns'

    # test objects deserialized from yaml mappings
    deserialized_no_coder_table_yaml =
      load_esourcemapping_yaml(no_coder_table.to_yaml, extra_whitelist_classes: [TestNoCoderTable])
    deserialized_ndr_table_yaml = load_esourcemapping_yaml(ndr_table.to_yaml)

    assert deserialized_no_coder_table_yaml.is_a?(NdrImport::NonTabular::Table)
    assert deserialized_ndr_table_yaml.is_a?(NdrImport::NonTabular::Table)

    assert_nil deserialized_no_coder_table_yaml.filename_pattern
    assert_equal deserialized_no_coder_table_yaml.klass, no_coder_table.klass
    assert_equal deserialized_no_coder_table_yaml.start_line_pattern, no_coder_table.start_line_pattern
    assert_equal deserialized_no_coder_table_yaml.columns, no_coder_table.columns

    assert_nil deserialized_ndr_table_yaml.filename_pattern
    assert_equal deserialized_ndr_table_yaml.klass, ndr_table.klass
    assert_equal deserialized_ndr_table_yaml.start_line_pattern, ndr_table.start_line_pattern
    assert_equal deserialized_ndr_table_yaml.columns, ndr_table.columns
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
    table1 = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                  :columns => column_level_klass_mapping)

    some_test_klass_mapping = [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
      { 'do_not_capture' => true }
    ]
    assert_equal some_test_klass_mapping,
                 table1.send(:mask_mappings_by_klass, 'SomeTestKlass')

    some_other_klass_mapping = [
      { 'do_not_capture' => true },
      { 'column' => 'two', 'klass' => %w(SomeTestKlass SomeOtherKlass) },
      { 'column' => 'three', 'klass' => 'SomeOtherKlass' }
    ]
    assert_equal some_other_klass_mapping,
                 table1.send(:mask_mappings_by_klass, 'SomeOtherKlass')

    table2 = NdrImport::Table.new(:header_lines => 2, :footer_lines => 1,
                                  :columns => column_level_klass_mapping_embedded_klasses)

    some_test_klass_mapping_embedded_klasses = [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => [['SomeTestKlass'], 'SomeOtherKlass'] },
      { 'do_not_capture' => true }
    ]
    assert_equal some_test_klass_mapping_embedded_klasses,
                 table2.send(:mask_mappings_by_klass, 'SomeTestKlass')

    some_other_klass_mapping_embedded_klasses = [
      { 'do_not_capture' => true },
      { 'column' => 'two', 'klass' => [['SomeTestKlass'], 'SomeOtherKlass'] },
      { 'column' => 'three', 'klass' => 'SomeOtherKlass' }
    ]
    assert_equal some_other_klass_mapping_embedded_klasses,
                 table2.send(:mask_mappings_by_klass, 'SomeOtherKlass')
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

  def test_varying_header_line_lengths_with_valid_header_row_including_nils
    lines = [
      [nil] << 'RIGHTALIGN1' << 'RIGHTALIGN2',
      %w(ONE TWO),
      %w(LEFTALIGN) << nil,
      %w(CENTRE1) << nil << 'CENTRE2',
      %w(UNO DOS)
    ].each

    table = NdrImport::Table.new(:header_lines => 4, :footer_lines => 0,
                                 :klass => 'SomeTestKlass',
                                 :columns => [{ 'column' => 'one' }, { 'column' => 'two' }])

    output = []
    table.transform(lines).each do |klass, fields, index|
      output << [klass, fields, index]
    end

    assert table.header_valid?

    expected_output = [['SomeTestKlass', { :rawtext => { 'one' => 'UNO', 'two' => 'DOS' } }, 4]]
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

  test 'should mutate regexp column names' do
    lines = [
      %w[1234 STRING_HEADING ABC123],
      %w[NUMERIC_ONLY STRING_VALUE ALPHA_NUMERIC]
    ].each

    table = NdrImport::Table.new(
      header_lines: 1,
      footer_lines: 0,
      klass: 'SomeTestKlass',
      columns: regexp_column_names
    )

    expected_output = [
      ['SomeTestKlass',
       { rawtext: { '1234' => 'NUMERIC_ONLY', 'string_heading' => 'STRING_VALUE', 'abc123' => 'ALPHA_NUMERIC' } },
       1]
    ]
    assert_equal expected_output, table.transform(lines).to_a
  end

  test 'should report header errors is regexp column names do not match' do
    lines = [
      %w[A1234Z STRING_HEADING ABC123],
      %w[NUMERIC_ONLY STRING_VALUE ALPHA_NUMERIC]
    ].each

    table = NdrImport::Table.new(
      header_lines: 1,
      footer_lines: 0,
      klass: 'SomeTestKlass',
      columns: regexp_column_names
    )

    exception = assert_raises(RuntimeError) { table.transform(lines).to_a }
    assert_equal 'Header is not valid! unexpected: ["a1234z"]', exception.message
  end

  private

  def simple_deserialized_table
    load_esourcemapping_yaml(<<~YML)
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

  def column_level_klass_mapping_embedded_klasses
    [
      { 'column' => 'one', 'klass' => 'SomeTestKlass' },
      { 'column' => 'two', 'klass' => [['SomeTestKlass'], 'SomeOtherKlass'] },
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

  def regexp_column_names
    [{ 'column' => /\A\d+\z/ },
     { 'column' => 'string_heading' },
     { 'column' => /\A[A-Z]+\d{3}\z/i }]
  end

  def get_yaml_mapping_order(yaml_mapping)
    yaml_mapping.split("\n").
      delete_if { |line| /-+/.match(line) }.
      map { |line| /(.*):/.match(line)[1].to_s }
  end
end
