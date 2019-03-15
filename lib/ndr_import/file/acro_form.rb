require 'pdf-reader'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is an AcroForm PDF file handler that returns a single table
    class AcroForm < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        [reader.fields_hash].each(&block)
      rescue NoMethodError
        raise "Failed to read #{SafeFile.basename(@filename)} as an AcroForm PDF"
      end

      def reader
        @reader ||= AcroFormReader.new(SafeFile.safepath_to_string(@filename))
      end
    end

    Registry.register(AcroForm, 'acroform')
  end
end
