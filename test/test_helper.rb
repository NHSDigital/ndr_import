require 'simplecov'
SimpleCov.start

require 'active_support/test_case'
require 'active_support/core_ext/string'
require 'ndr_support/safe_path'
require 'ndr_import'
require 'yaml'

begin
  # Shim for Test::Unit vs. Minitest:
  require 'active_support/testing/autorun'
rescue LoadError
  # Rails 4+ only
end

ActiveSupport.test_order = :random if ActiveSupport.respond_to?(:test_order=)

# The default changes to UTC in Rails 4.
# TODO: ndr_support should cope...
ActiveRecord::Base.default_timezone = :local

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'
NdrImport::StandardMappings.mappings = YAML.load_file(
  File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml')
)

require 'mocha/minitest'
