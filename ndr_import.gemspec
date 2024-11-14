lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ndr_import/version'

Gem::Specification.new do |spec|
  spec.name          = 'ndr_import'
  spec.version       = NdrImport::VERSION
  spec.authors       = ['NCRS Development Team']
  spec.email         = []
  spec.summary       = 'NDR Import'
  spec.description   = 'NDR ETL Importer'
  spec.homepage      = 'https://github.com/NHSDigital/ndr_import'
  spec.license       = 'MIT'

  gem_files          = %w[CHANGELOG.md CODE_OF_CONDUCT.md LICENSE.txt MIT-LICENSE README.md Rakefile
                          app config db exe lib]
  spec.files         = `git ls-files -z`.split("\x0").
                       select { |f| gem_files.include?(f.split('/')[0]) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activesupport', '>= 6.1', '< 8.1'
  spec.add_dependency 'ndr_support', '>= 5.3.2', '< 6'

  spec.add_dependency 'rubyzip', '~> 2.0'
  spec.add_dependency 'roo', '~> 2.0'

  spec.add_dependency 'avro', '~> 1.11.0'
  spec.add_dependency 'bio-vcf', '~> 0.9.5'
  spec.add_dependency 'csv'
  spec.add_dependency 'docx', '~> 0.3'
  spec.add_dependency 'msworddoc-extractor', '0.2.0'
  spec.add_dependency 'nokogiri', '~> 1.8', '>= 1.8.5'
  spec.add_dependency 'ooxml_decrypt'
  spec.add_dependency 'pdf-reader', '~> 2.1'
  spec.add_dependency 'roo-xls'
  spec.add_dependency 'seven-zip', '~> 1.4'
  spec.add_dependency 'spreadsheet', '1.2.6'

  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'ndr_dev_support', '>= 3.1.3'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-test'
  spec.add_development_dependency 'terminal-notifier-guard' if RUBY_PLATFORM =~ /darwin/
  spec.add_development_dependency 'simplecov'
end
