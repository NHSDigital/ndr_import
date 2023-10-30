require 'simplecov'
SimpleCov.start

require 'active_support'
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
if ActiveRecord.respond_to?(:default_timezone=)
  ActiveRecord.default_timezone = :local
else
  ActiveRecord::Base.default_timezone = :local # Rails <= 6.1
end

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'
NdrImport::StandardMappings.mappings = YAML.load_file(
  File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml')
)

# Different Rubies report this differently:
CORRUPTED_QUOTES_MESSAGE_PATTERN = /(
  Missing\sor\sstray\squote|
  col_sep_split|
  value\safter\squoted\sfield\sisn't\sallowed
)/x

require 'mocha/minitest'

module ActiveSupport
  class TestCase
    # Safely load YAML that could be included in esourcemappings
    # We define this as both a class and instance method, for convenience of use
    def self.load_esourcemapping_yaml(yaml, extra_whitelist_classes: [])
      white_listed_classes = [NdrImport::NonTabular::Table, NdrImport::Table, NdrImport::Xml::Table,
                              Range, Regexp, RegexpRange, Symbol] + extra_whitelist_classes
      YAML.safe_load(yaml, permitted_classes: white_listed_classes)
    end

    def load_esourcemapping_yaml(...)
      self.class.load_esourcemapping_yaml(...)
    end
  end
end
