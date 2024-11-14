# encoding: UTF-8
require 'test_helper'

# This tests the StandardMappings configuration class
class StandardMappingsTest < ActiveSupport::TestCase
  test 'should not raise exception on reconfiguring NdrImport::StandardMappings' do
    assert_nothing_raised do
      NdrImport::StandardMappings.mappings =
        YAML.load_file(SafePath.new('permanent_test_files').join('standard_mappings.yml'))
    end
  end

  test 'should raise exception on setting non-hash standard mappings' do
    assert_raise ArgumentError do
      NdrImport::StandardMappings.mappings = true
    end
  end

  test 'should return mappings' do
    safe_path = SafePath.new('permanent_test_files').join('standard_mappings.yml')
    assert_instance_of Hash, NdrImport::StandardMappings.mappings
    assert_equal YAML.load_file(safe_path), NdrImport::StandardMappings.mappings
  end
end
