require 'simplecov'
SimpleCov.start

require 'active_support/test_case'
require 'ndr_support/safe_path'
require 'ndr_import'
require 'yaml'

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'
NdrImport::StandardMappings.mappings = YAML.load_file(
  File.expand_path(File.dirname(__FILE__) + '/resources/standard_mappings.yml')
)
