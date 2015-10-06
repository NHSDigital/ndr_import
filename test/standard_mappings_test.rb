# encoding: UTF-8
require 'test_helper'

# This tests the StandardMappings configuration class
class StandardMappingsTest < ActiveSupport::TestCase
  test 'should raise exception on reconfiguring NdrImport::StandardMappings' do
    assert_nothing_raised do
      NdrImport::StandardMappings.configure!(
        File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml')
      )
    end
  end

  test 'should return fs_path' do
    assert_nothing_raised do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml'),
                   NdrImport::StandardMappings.fs_path
    end
  end
end
