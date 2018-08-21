require 'zip'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a zip file handler that returns tables from the extracted files.
    class Zip < Base
      def initialize(filename, format, options = {})
        super
        @pattern = options['pattern'] || //
        @unzip_path = options['unzip_path']

        validate_unzip_path_is_safe!
      end

      def files(&block)
        fail 'Not allowed in external environment' if defined?(::Rails) && ::Rails.env.external?

        return enum_for(:files) unless block

        destination = @unzip_path.join(Time.current.strftime('%H%M%S%L'))
        FileUtils.mkdir_p(SafeFile.safepath_to_string(destination))

        ::Zip::File.open(SafeFile.safepath_to_string(@filename)) do |zipfile|
          unzip_entries(zipfile, destination, &block)
        end
      end

      # Zip files produce files, never tables.
      def tables
        fail 'Zip#tables should never be called'
      end

      private

      # Unzip the zip file entry and enumerate over it
      def unzip_entries(zipfile, destination, &block)
        zipfile.entries.each do |entry|
          # SECURE: TPG 2010-11-1: The path is stripped from the zipfile entry when extracted
          basename = ::File.basename(entry.name)
          next unless entry.file? && basename.match(@pattern)

          unzipped_filename = destination.join(basename)
          zipfile.extract(entry, unzipped_filename)

          unzipped_files(unzipped_filename, &block)
        end
      end

      # Enumerate over an unzipped file like any other
      def unzipped_files(unzipped_filename, &block)
        Registry.files(unzipped_filename, @options).each do |filename|
          block.call(filename)
        end
      end

      def validate_unzip_path_is_safe!
        SafeFile.safepath_to_string(@unzip_path)
      end
    end

    Registry.register(Zip, 'zip')
  end
end
