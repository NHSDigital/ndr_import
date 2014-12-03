# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# automatically check Ruby code style with Rubocop when files are modified
guard :rubocop, :all_on_start => false, :keep_failed => false do
  watch(/.+\.rb$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end

guard :test do
  watch(/^test\/.+_test\.rb$/)
  watch('test/test_helper.rb')  { 'test' }

  # Non-rails
  watch(%r{^lib/ndr_import/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
end
