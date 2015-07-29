require 'simplecov'
SimpleCov.start

require 'active_support/test_case'
require 'ndr_support/safe_path'
require 'ndr_import'
require 'yaml'

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'
NdrImport::StandardMappings.configure!(
  File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml')
)

module ActiveSupport
  class TestCase
    # A useful helper to make 'assert !condition' statements more readable
    def deny(condition, message = 'No further information given')
      assert !condition, message
    end
  end
end
