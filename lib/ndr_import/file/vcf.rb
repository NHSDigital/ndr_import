require 'bio-vcf/vcfline'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a vcf file handler that returns a single table.
    class Vcf < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        ::File.read(@filename).each_line do |line|
          next if line =~ /^##/

          yield BioVcf::VcfLine.parse(line)
        end
      end
    end
    Registry.register(Vcf, 'vcf')
  end
end
