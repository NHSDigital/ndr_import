require 'active_support/test_case'
require 'ndr_import'
require 'yaml'

StandardMappings.configure! File.dirname(__FILE__) + '/resources/standard_mappings.yml'

module ActiveSupport
  class TestCase
    # A useful helper to make 'assert !condition' statements more readable
    def deny(condition, message = 'No further information given')
      assert !condition, message
    end
  end
end
