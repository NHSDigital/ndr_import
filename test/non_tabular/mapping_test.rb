require 'test_helper'

# This tests the NdrImport::NonTabular::Mapping mapping class
class MappingTestTest < ActiveSupport::TestCase
  def test_should_raise_error_with_no_non_tabular_row
    assert_raise NdrImport::MappingError do
      NdrImport::NonTabular::Mapping.new(
        'columns' => [{ 'column' => 'one' }]
      )
    end
  end

  def test_should_raise_error_with_no_non_tabular_row_start_line_pattern
    assert_raise NdrImport::MappingError do
      NdrImport::NonTabular::Mapping.new(
        'non_tabular_row' => nil,
        'columns' => [{ 'column' => 'one' }]
      )
    end

    assert_raise NdrImport::MappingError do
      NdrImport::NonTabular::Mapping.new(
        'non_tabular_row' => { 'start_line_pattern' => nil },
        'columns' => [{ 'column' => 'one' }]
      )
    end
  end

  def test_should_initialize_with_non_tabular_row
    mapping = NdrImport::NonTabular::Mapping.new(
      'non_tabular_row' => { 'start_line_pattern' => /\A-*\z/ },
      'columns' => [{ 'column' => 'one' }]
    )
    assert_equal(/\A-*\z/, mapping.start_line_pattern)
  end
end
