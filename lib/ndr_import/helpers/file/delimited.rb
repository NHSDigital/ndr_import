require 'ndr_support/safe_file'
require 'ndr_import/csv_library'

module NdrImport
  module Helpers
    module File
      # This mixin adds delimited file functionality to unified importers.
      module Delimited
        # Read a plain text CSV file, return an array of the content
        def read_csv_file(path, liberal = false)
          # Read the page below when encountering "CSV::IllegalFormatError" error caused by CSV
          # file generated at MAC OS
          # http://stackoverflow.com/questions/1549139/ruby-cannot-parse-excel-file-exported-as-csv-in-os-x

          read_delimited_file(path, nil, liberal)
        end

        # Slurp the entire file into an array of lines.
        def read_delimited_file(path, col_sep = nil, liberal = false)
          delimited_rows(path, col_sep, liberal).to_a
        end

        # Iterate through the file table by table, yielding each one in turn.
        def delimited_tables(path, col_sep = nil, liberal = false)
          return enum_for(:delimited_tables, path, col_sep, liberal) unless block_given?

          yield nil, delimited_rows(path, col_sep, liberal)
        end

        # Iterate through the file line by line, yielding each one in turn.
        def delimited_rows(path, col_sep = nil, liberal = false)
          return enum_for(:delimited_rows, path, col_sep, liberal) unless block_given?

          safe_path = SafeFile.safepath_to_string(path)
          encodings = determine_encodings!(safe_path, col_sep, liberal)

          # By now, we know `encodings` should let us read the whole
          # file succesfully; if there are problems, we should crash.
          CSVLibrary.foreach(safe_path, **encodings) do |line|
            yield line.map(&:to_s)
          end
        end

        private

        # Derive the source encoding by trying all supported encodings.
        # Returns first set of working options, or raises if none could be found.
        def determine_encodings!(safe_path, col_sep, liberal)
          # delimiter encoding => # FasterCSV encoding string
          supported_encodings = {
            'UTF-8'        => 'r:bom|utf-8',
            'Windows-1252' => 'r:windows-1252:utf-8'
          }

          successful_options = try_each_encoding(safe_path, col_sep, liberal, supported_encodings)

          # We tried them all, and none worked:
          unless successful_options
            raise "None of the encodings #{supported_encodings.values.inspect} were successful!"
          end

          successful_options
        end

        def try_each_encoding(safe_path, col_sep, liberal, supported_encodings)
          supported_encodings.each do |delimiter_encoding, access_mode|
            begin
              options = {
                col_sep: (col_sep || ',').force_encoding(delimiter_encoding),
                liberal_parsing: liberal,
                mode: access_mode
              }

              row_num = 0
              # Iterate through the file; if we reach the end, this encoding worked:
              CSVLibrary.foreach(safe_path, **options) { |_line| row_num += 1 }
              return options
            rescue ArgumentError => e
              next if e.message =~ /invalid byte sequence/ # This encoding didn't work
              raise(e)
            rescue RegexpError => e
              next if e.message =~ /invalid multibyte character/ # This encoding didn't work
              raise(e)
            rescue CSVLibrary::MalformedCSVError => e
              next if e.message =~ /Invalid byte sequence/ # This encoding didn't work
              raise malformed_csv_error(e, col_sep, row_num + 1, safe_path)
            end
          end
        end

        def malformed_csv_error(exception, col_sep, line, safe_path)
          type    = (col_sep ? col_sep.inspect + ' delimited' : 'CSV')
          message = "Invalid #{type} format on row #{line} of #{::File.basename(safe_path)}"

          if exception.respond_to?(:line_number)
            base_message = exception.message.chomp(" in line #{exception.line_number}.")
            exception.class.new("#{message}. Original: #{base_message}", exception.line_number)
          else
            exception.class.new("#{message}. Original: #{exception.message}")
          end
        end
      end
    end
  end
end
