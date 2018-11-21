require 'seven_zip_ruby'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a 7zip file handler that returns tables from the extracted files.
    class SevenZip < Base
      def initialize(filename, format, options = {})
        super
        @pattern = options['pattern'] || //
        @unzip_path = options['unzip_path']
        @password = options['password']

        validate_unzip_path_is_safe!
      end

      def files(&block)
        raise 'Not allowed in external environment' if defined?(::Rails) && ::Rails.env.external?

        return enum_for(:files) unless block

        destination = @unzip_path.join(Time.current.strftime('%H%M%S%L'))
        FileUtils.mkdir_p(SafeFile.safepath_to_string(destination))

        ::File.open(SafeFile.safepath_to_string(@filename), 'rb') do |zipfile|
          unzip_entries(zipfile, destination, &block)
        end
      end

      # 7zip files produce files, never tables.
      def tables
        raise 'SevenZip#tables should never be called'
      end

      private

      # Unzip the 7zip file entry and enumerate over it
      def unzip_entries(zipfile, destination, &block)
        SevenZipRuby::Reader.open(zipfile, password: @password) do |szr|
          szr.entries.each do |entry|
            # SECURE: TPG 2018-11-21: The path is stripped from the zipfile entry when extracted
            basename = ::File.basename(entry.path)
            next unless entry.file? && basename.match(@pattern)

            unzipped_filename = destination.join(basename)
            szr.extract([entry], unzipped_filename)

            unzipped_files(unzipped_filename, &block)
          end
        end
      end

      # Enumerate over an unzipped file like any other
      def unzipped_files(unzipped_filename)
        Registry.files(unzipped_filename, @options).each do |filename|
          yield(filename)
        end
      end

      def validate_unzip_path_is_safe!
        SafeFile.safepath_to_string(@unzip_path)
      end
    end

    Registry.register(SevenZip, '7z')
  end
end
