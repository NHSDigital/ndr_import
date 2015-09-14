require 'ndr_support/safe_file'
require 'ndr_import/csv_library'

module NdrImport
  module Helpers
    module File
      # This mixin adds delimited file functionality to unified importers.
      module Delimited
        # Read a plain text CSV file, return an array of the content
        def read_csv_file(path)
          # Read the page below when encountering "CSV::IllegalFormatError" error caused by CSV
          # file generated at MAC OS
          # http://stackoverflow.com/questions/1549139/ruby-cannot-parse-excel-file-exported-as-csv-in-os-x

          read_delimited_file(path)
        end

        # Slurp the entire file into an array of lines.
        def read_delimited_file(path, col_sep = nil)
          each_delimited_row(path, col_sep).to_a
        end

        # Iterate through the file table by table, yielding each one in turn.
        def each_delimited_table(path, col_sep = nil)
          return enum_for(:each_delimited_table, path, col_sep) unless block_given?

          yield nil, each_delimited_row(path, col_sep)
        end

        # Iterate through the file line by line, yielding each one in turn.
        def each_delimited_row(path, col_sep = nil)
          return enum_for(:each_delimited_row, path, col_sep) unless block_given?

          safe_path = SafeFile.safepath_to_string(path)
          encodings = determine_encodings!(safe_path, col_sep)

          # By now, we know `encodings` should let us read the whole
          # file succesfully; if there are problems, we should crash.
          CSVLibrary.foreach(safe_path, encodings) do |line|
            yield line.map(&:to_s) unless line.length <= 5
          end
        end

        private

        # Derive the source encoding by trying all supported encodings.
        # Returns first set of working options, or raises if none could be found.
        def determine_encodings!(safe_path, col_sep = nil)
          # delimiter encoding => # FasterCSV encoding string
          supported_encodings = {
            'UTF-8'        => 'bom|utf-8',
            'Windows-1252' => 'windows-1252:utf-8'
          }

          successful_options = nil
          supported_encodings.each do |delimiter_encoding, csv_encoding|
            begin
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
    end
  end
end
