require 'bundler/gem_tasks'
require 'rake/testtask'
require 'ndr_dev_support/tasks'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = false
end

desc 'Run tests'
task :default => :test
