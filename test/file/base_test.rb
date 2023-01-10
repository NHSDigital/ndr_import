require 'test_helper'
require 'ndr_import/file/registry'

module NdrImport
  module File
    # Base file handler tests
    class BaseTest < ActiveSupport::TestCase
      # Handles a single table file, but for test purposes,
      # I could be bothered to implement it fully
      class SingleTableLazyDeveloper < ::NdrImport::File::Base
      end

      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should fail on not implementing rows' do
        Registry.register(SingleTableLazyDeveloper, 'lazy_dev')

        exception = assert_raises(RuntimeError) do
          file_path = @permanent_test_files.join('normal.csv')
          handler = SingleTableLazyDeveloper.new(file_path, 'lazy_dev')

          handler.tables.each do |tablename, sheet|
            assert_nil tablename
            assert_instance_of Enumerator, sheet
            sheet.to_a
          end
        end

        msg = 'Implement NdrImport::File::BaseTest::SingleTableLazyDeveloper#rows'
        assert_equal msg, exception.message
      ensure
        Registry.unregister('lazy_dev')
      end

      test 'should not fail when set up with an readable safepath' do
        assert Base.new(SafePath.new('test_space_r'), nil)
        assert Base.new(SafePath.new('test_space_rw'), nil)
      end

      test 'should fail when set up with an unreadable safepath' do
        assert_raises(SecurityError) { Base.new(SafePath.new('test_space_w'), nil) }
      end

      test 'should fail when set up with a non-safepath' do
        exception = assert_raises(ArgumentError) { Base.new(NdrImport.root, nil) }
        assert exception.message =~ /file_name should be of type SafePath, but it is String/
      end

      test 'should fail when set up with an unsupported stream' do
        ::File.open(@permanent_test_files.join('normal.csv'), 'r') do |file|
          refute Base.can_stream_data?
          assert_raise ::ArgumentError do
            Base.new(file, nil)
          end
        end
      end
    end
  end
end
