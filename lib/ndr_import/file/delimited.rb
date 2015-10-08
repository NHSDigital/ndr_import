require 'ndr_support/safe_file'
require 'ndr_import/csv_library'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a delimited file handler that returns a single table.
    class Delimited < Base
      DELIMITED_COL_SEP = {
        'csv' => nil,
        'pipe' => '|',
        'thorn' => "\xfe" # high-ascii (lower case thorn) delimited files
      }

      def initialize(filename, format, options = {})
        super

        @options['col_sep'] ||= DELIMITED_COL_SEP[format]
      end

      private

      # Iterate through the file line by line, yielding each one in turn.
      def rows
        return enum_for(:rows) unless block_given?

        safe_path = SafeFile.safepath_to_string(@filename)
        encodings = determine_encodings!(safe_path)

        # By now, we know `encodings` should let us read the whole
        # file succesfully; if there are problems, we should crash.
        CSVLibrary.foreach(safe_path, encodings) do |line|
          yield line.map(&:to_s) unless line.length <= 5
        end
      end

      # Derive the source encoding by trying all supported encodings.
      # Returns first set of working options, or raises if none could be found.
      def determine_encodings!(safe_path)
        # delimiter encoding => # FasterCSV encoding string
        supported_encodings = {
          'UTF-8'        => 'bom|utf-8',
          'Windows-1252' => 'windows-1252:utf-8'
        }

        successful_options = nil
        supported_encodings.each do |delimiter_encoding, csv_encoding|
          begin
            col_sep = @options['col_sep']
            options = {
              :col_sep  => (col_sep || ',').force_encoding(delimiter_encoding),
              :encoding => csv_encoding
            }

            row_num = 0
            # Iterate through the file; if we reach the end, this encoding worked:
            CSVLibrary.foreach(safe_path, options) { |_line| row_num += 1 }
          rescue ArgumentError => e
            next if e.message =~ /invalid byte sequence/ # This encoding didn't work
            raise(e)
          rescue CSVLibrary::MalformedCSVError => e
            description = (col_sep ? col_sep.inspect + ' delimited' : 'CSV')

            raise(CSVLibrary::MalformedCSVError, "Invalid #{description} format " \
              "on row #{row_num + 1} of #{::File.basename(safe_path)}. Original: #{e.message}")
          end

          # We got this far => encoding choice worked:
          successful_options = options
          break
        end

        # We tried them all, and none worked:
        unless successful_options
          fail "None of the encodings #{supported_encodings.values.inspect} were successful!"
        end

        successful_options
      end
    end

    Registry.register(Delimited, 'csv', 'pipe', 'thorn')
  end
end
