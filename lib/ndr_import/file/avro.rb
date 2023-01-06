require 'avro'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is an avro file handler that returns a single table.
    class Avro < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        # Create an instance of DatumReader
        reader = ::Avro::IO::DatumReader.new
        # Open items.avro file in read mode
        file   = ::File.open(@filename, 'rb')
        # Equivalent to DataFileReader instance creation in Java
        dr     = ::Avro::DataFile::Reader.new(file, reader)

        dr.each_with_index do |avro_row, i|
          # Ensure the first row is always the "header"
          yield(avro_row.keys) if i.zero?
          yield(avro_row)
        end
      rescue StandardError => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end
    end
    Registry.register(Avro, 'avro')
  end
end
