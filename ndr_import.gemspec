# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ndr_import/version'

Gem::Specification.new do |spec|
  spec.name          = 'ndr_import'
  spec.version       = NdrImport::VERSION
  spec.authors       = ['NCRS Development Team']
  spec.email         = []
  spec.summary       = 'NDR Import'
  spec.description   = 'NDR ETL Importer'
  spec.homepage      = ''

  # Exclude older versions of this gem from the package.
  spec.files         = `git ls-files -z`.split("\x0").reject{|s| s=~ /^pkg\//}
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 3.2.18'
  spec.add_dependency 'ndr_support', '~> 2.0'

  spec.add_dependency 'rubyzip', '>= 0.9.1', '< 1.0.0', '0.9.9' # rubyzip (1.0.0) requires Ruby version >= 1.9.2.
  # roo (1.11.0) requires Ruby version >= 1.9.0
  spec.add_dependency 'roo', '~> 1.10.3', '< 1.11.0'
  # roo requires nokogiri >=1.5, but nokogiri (1.6.1) requires Ruby version >= 1.9.2.
  spec.add_dependency 'nokogiri', '>= 1.5.11', '< 1.6' # Enable roo 1.9.x to run on Ruby 1.8.7
  spec.add_dependency 'spreadsheet', '0.7.3'           # Aligning with encore
  spec.add_dependency 'pdf-reader', '1.2.0' # Later versions require Ruby 1.9
  spec.add_dependency 'msworddoc-extractor', '0.1.0'

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-test'
  spec.add_development_dependency 'terminal-notifier-guard' if RUBY_PLATFORM =~ /darwin/
  spec.add_development_dependency 'simplecov'
end
