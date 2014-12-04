require 'active_support/test_case'
require 'ndr_import'
require 'yaml'

module ActiveSupport
  class TestCase
    # A useful helper to make 'assert !condition' statements more readable
    def deny(condition, message = 'No further information given')
      assert !condition, message
    end
  end
end
