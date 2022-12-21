require 'test_helper'
require 'ndr_import/file/avro'

module NdrImport
  module File
    # Avro file handler tests
    class AvroTest < ActiveSupport::TestCase
      def setup
        @file_path = SafePath.new('permanent_test_files').join('fake_dids.avro')
      end

      test 'should read avro files' do
        handler = NdrImport::File::Avro.new(@file_path, nil)
        rows    = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Hash })
        assert_equal 10, rows.to_a.length
      end
    end
  end
end
