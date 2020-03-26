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
  spec.homepage      = 'https://github.com/PublicHealthEngland/ndr_import'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(docs|test|spec|features)/}) }
  end
  spec.files         -= %w[.travis.yml] # Not needed in the gem
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activesupport', '>= 5.0', '< 7'
  spec.add_dependency 'ndr_support', '>= 5.3.2', '< 6'

  spec.add_dependency 'rubyzip', '~> 2.0'
  spec.add_dependency 'roo', '~> 2.0'

  spec.add_dependency 'docx', '~> 0.3'
  spec.add_dependency 'msworddoc-extractor', '0.2.0'
  spec.add_dependency 'nokogiri', '~> 1.8', '>= 1.8.5'
  spec.add_dependency 'ooxml_decrypt'
  spec.add_dependency 'pdf-reader', '~> 2.1'
  spec.add_dependency 'roo-xls'
  spec.add_dependency 'seven_zip_ruby', '~> 1.2'
  spec.add_dependency 'spreadsheet', '1.2.6'

  spec.required_ruby_version = '>= 2.5'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'ndr_dev_support', '>= 3.1.3'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-test'
  spec.add_development_dependency 'terminal-notifier-guard' if RUBY_PLATFORM =~ /darwin/
  spec.add_development_dependency 'simplecov'
end
