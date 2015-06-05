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

        def read_delimited_file(path, field_separator = nil)
          return read_delimited_file_faster(path, field_separator) if CSVLibrary.fastercsv?

          recs = []
          rownum = 0
          begin
            CSVLibrary.open(SafeFile.safepath_to_string(path), 'r', field_separator) { |line|
              recs << line.map(&:to_s) unless line.nitems <= 5
              rownum += 1
            }
          rescue CSVLibrary::IllegalFormatError => e
            raise(CSVLibrary::IllegalFormatError, "Invalid #{field_separator ? (field_separator.inspect + ' delimited') : 'CSV'} format on row #{rownum + 1} of #{SafeFile.basename(path)}")
          end
          recs
        end

        # TODO: Post-FasterCSV, make this the only csv-reading method.
        def read_delimited_file_faster(path, col_sep)
          records, row_num = nil, nil

          supported_encodings = {
            # delimiter encoding => # FasterCSV encoding string
            'UTF-8'        => 'bom|utf-8',
            'Windows-1252' => 'windows-1252:utf-8'
          }
          successful_encoding = supported_encodings.detect do |delimiter_encoding, csv_encoding|
            begin
              # Reset if a previous encoding failed part way through:
              records, row_num = [], 0

              options = {
                :col_sep  => (col_sep || ',').force_encoding(delimiter_encoding),
                :encoding => csv_encoding
              }

              CSVLibrary.foreach(SafeFile.safepath_to_string(path), options) do |line|
                records << line.map(&:to_s) unless line.length <= 5
                row_num += 1
              end
            rescue ArgumentError => e
              # This csv_encoding choice wasn't the right one:
              next if e.message =~ /invalid byte sequence/
              # Some other issue we're not trying to catch:
              raise(e)
            rescue CSVLibrary::MalformedCSVError => e
              description = (col_sep ? col_sep.inspect + ' delimited' : 'CSV')

              raise(CSVLibrary::MalformedCSVError, "Invalid #{description} format " \
                "on row #{row_num + 1} of #{SafeFile.basename(path)}. Original: #{e.message}")
            end

            true # This encoding worked!
          end

          unless successful_encoding
            fail "None of the encodings #{supported_encodings.values.inspect} were successful!"
          end

          # Trim any BOM manually on Ruby 1.8.x, as the 'bom|...'
          # encoding option is Ruby 1.9+ only.
          if RUBY_VERSION =~ /^1\.8/
            first_cell = records.first.try(:first)
            first_cell && first_cell.gsub!("\xEF\xBB\xBF", '')
          end

          records
        end
      end
    end
  end
end