require 'test_helper'
require 'ndr_import/helpers/file/word'

# Word file helper tests
class WordTest < ActiveSupport::TestCase
  # This is a test importer class to test the Word file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Word
  end

  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
    @importer  = TestImporter.new
  end

  test 'read_word_file helper should read word file' do
    file_content = @importer.send(:read_word_file, @permanent_test_files.join('hello_world.doc'))
    assert_equal file_content, ['Hello world, this is a word document']
  end

  test 'read_word_file helper should raise exception on invalid word file' do
    assert_raises RuntimeError do
      @importer.send(:read_word_file, @permanent_test_files.join('not_a_word_file.doc'))
    end
  end
end
