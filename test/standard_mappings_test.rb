# encoding: UTF-8
require 'test_helper'

# This tests the StandardMappings configuration class
class StandardMappingsTest < ActiveSupport::TestCase
  test 'should raise exception on reconfiguring StandardMappings' do
    assert_raise RuntimeError do
      StandardMappings.configure! 'some/path/again'
    end
  end

  test 'should return fs_path' do
    assert_nothing_raised do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml'),
                   StandardMappings.fs_path
    end
  end
end
