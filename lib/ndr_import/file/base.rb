require 'ndr_support/safe_file'
require 'ndr_import/csv_library'
require_relative 'registry'

module NdrImport
  # This is the base of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # All common base file handler logic is defined here.
    class Base
      def initialize(filename, format, delimiter, options = {})
        @filename  = filename
        @format    = format
        @delimiter = delimiter
        @options   = options

        validate_filename_is_safe_and_readable!
      end

      # This method iterates over the files in the given file and yields the filenames.
      # For a zip file it will yield for every file in the zip file and for (currently)
      # every other file it will yield its own filename.
      #
      # As the majority of files are not containers (of other files), the Base implementation
      # is defined for these handlers. If your file contains more than one file, then
      # override this method. If you do overide this method, then you will probably want
      # to raise an exception if your tables method is called. E.g. a zip file handler would
      # produce files, never tables.
      def files
        return enum_for(:files) unless block_given?

        yield @filename
      end

      # This method iterates over the tables in the given file and yields with two arguments:
      # a tablename and a row enumerator (for that table). For a spreadsheet it may yield for
      # every worksheet in the file and for a CSV file it will only yield once (the entire
      # file is one table).
      #
      # As single table files are in the majority, the Base implementation is defined for
      # single table handlers and you will only need to implement the rows iterator. If your
      # file contains more than one table, then override this method.
      #
      # NOTE: for single table handlers, the tablename argument should be nil.
      def tables
        return enum_for(:tables) unless block_given?

        yield nil, rows
      end

      private

      # If this is a single table file handler then this method must be implemented by
      # the subclass. It iterates over each of the rows of the current table (the whole
      # file in this case) and should work in both the block and non-block form, returning
      # an Enumerator in the latter case. We recommend that you follow the following pattern:
      #
      # def rows
      #   return enum_for(:rows) unless block_given?
      #
      #   ... your code goes here ...
      # end
      #
      def rows
        fail "Implement #{self.class}#rows"
      end

      def validate_filename_is_safe_and_readable!
        SafeFile.safepath_to_string(@filename)

        # Ensure that we're allowed to read from the safe path:
        # (they can be configured to be write-only, for example)
        SafeFile.verify_mode(@filename, 'r')
      end
    end
  end
end
