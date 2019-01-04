require 'ndr_support/safe_file'
require 'ndr_import/csv_library'
require 'ndr_import/helpers/file/delimited'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a delimited file handler that returns a single table.
    class Delimited < Base
      include Helpers::File::Delimited

      DELIMITED_COL_SEP = {
        'csv' => nil
      }
      def initialize(filename, format, options = {})
        super

        @options['col_sep'] ||= DELIMITED_COL_SEP[format]
      end

      private

      # Iterate through the file line by line, yielding each one in turn.
      def rows
        return enum_for(:rows) unless block_given?

        col_sep = @options['col_sep']
        liberal = @options['liberal_parsing'].presence

        delimited_rows(@filename, col_sep, liberal) { |row| yield row }
      end

      # Cache working encodings, so that resetting the enumerator
      # doesn't mean the need to recalculate this:
      def determine_encodings!(*)
        @encoding ||= super
      end
    end

    Registry.register(Delimited, 'csv', 'delimited')
  end
end
