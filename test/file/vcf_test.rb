require 'test_helper'
require 'ndr_import/file/vcf'

module NdrImport
  module File
    # Vcf file handler tests
    class VcfTest < ActiveSupport::TestCase
      def setup
        @file_path = SafePath.new('permanent_test_files').join('sample_vcf.vcf')
      end

      test 'should read vcf files' do
        handler = NdrImport::File::Vcf.new(@file_path, nil)
        rows    = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Array })
        assert_equal 7, rows.to_a.length
      end
    end
  end
end
