require 'test_helper'

# This tests the NdrImport::FixedWidth::Table mapping class
module FixedWidth
  class TableTest < ActiveSupport::TestCase
    def test_transform_fixed_width_line
      table = NdrImport::FixedWidth::Table.new(header_lines: 2,
                                               footer_lines: 1,
                                               klass: 'SomeTestKlass',
                                               columns: fixed_width_column_mapping)

      enum = table.transform_line('123  abcdexyz', 2)
      assert_instance_of Enumerator, enum
      output = []
      enum.each do |klass, fields, index|
        output << [klass, fields, index]
      end

      expected_output = [
        ['SomeTestKlass', { rawtext: { 'one' => '123  ', 'two' => 'abcde', 'three' => 'xyz' } }, 2]
      ]
      assert_equal expected_output.sort, output.sort
    end

    private

    def fixed_width_column_mapping
      [
        { 'column' => 'one',   'unpack_pattern' => 'a5' },
        { 'column' => 'two',   'unpack_pattern' => 'a5' },
        { 'column' => 'three', 'unpack_pattern' => 'a3' }
      ]
    end
  end
end
