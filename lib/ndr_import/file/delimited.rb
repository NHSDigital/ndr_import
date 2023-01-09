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
        'csv' => nil
      }

      def initialize(filename_or_stream, format, options = {})
        super(filename_or_stream, format, options)

        @options['col_sep'] ||= DELIMITED_COL_SEP[format]
      end

      private

      # Iterate through the file line by line, yielding each one in turn.
      def rows
        return enum_for(:rows) unless block_given?

        col_sep = @options['col_sep']
        liberal = @options['liberal_parsing'].presence

        delimited_rows(@stream || @filename, col_sep, liberal) { |row| yield row }
      end

      # Iterate through the file line by line, yielding each one in turn.
      def delimited_rows(path, col_sep = nil, liberal = false)
        return enum_for(:delimited_rows, path, col_sep, liberal) unless block_given?

        safe_path = safepath_or_stream(path)
        options = determine_encodings!(safe_path, col_sep, liberal)

        # By now, we know `options` should let us read the whole
        # file succesfully; if there are problems, we should crash.
        CSV.foreach(safe_path, options.delete(:mode), **options) do |line|
          yield line.map(&:to_s)
        end
      end

      private

      # Cache working encodings, so that resetting the enumerator
      # doesn't mean the need to recalculate this.
      # Derive the source encoding by trying all supported encodings.
      # Returns first set of working options, or raises if none could be found.
      def determine_encodings!(safe_path, col_sep, liberal)
        return @encoding if defined? @encoding

        # delimiter encoding => # CSV encoding string
        supported_encodings = {
          'UTF-8'        => 'r:bom|utf-8',
          'Windows-1252' => 'r:windows-1252:utf-8'
        }

        successful_options = try_each_encoding(safe_path, col_sep, liberal, supported_encodings)

        # We tried them all, and none worked:
        unless successful_options
          raise "None of the encodings #{supported_encodings.values.inspect} were successful!"
        end

        @encoding = successful_options
      end

      def try_each_encoding(safe_path, col_sep, liberal, supported_encodings)
        supported_encodings.each do |delimiter_encoding, access_mode|
          begin
            options = {
              col_sep: (col_sep || ',').force_encoding(delimiter_encoding),
              liberal_parsing: liberal
            }

            row_num = 0
            # Iterate through the file; if we reach the end, this encoding worked:
            CSV.foreach(safe_path, access_mode, **options) { |_line| row_num += 1 }
            return options.merge(mode: access_mode)
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

    Registry.register(Delimited, 'csv', 'delimited')
  end
end
