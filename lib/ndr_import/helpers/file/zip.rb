require 'ndr_support/safe_file'

module NdrImport
  module Helpers
    module File
      # This mixin adds Zip functionality to unified importers.
      module Zip
        private

        # Unzip the file, creating the destination directory if necessary.
        # A pattern can be provided to only extract required files.
        def unzip_file(source, destination, pattern = //)
          # SECURE TVB Mon Aug 13 14:41:05 BST 2012 : SafePath will raise exception if insecure
          # path is constructed
          # SafeFile.safepath_to_string will make sure that the arguments are from type SafePath

          # SECURE: BNS 2010-09-21 (for external access)
          fail 'Not allowed in external environment' if defined?(::Rails) && ::Rails.env.external?

          require 'zip'
          # TODO: Abort if destination directory already exists...
          FileUtils.mkdir_p(SafeFile.safepath_to_string(destination))

          ::Zip::File.open(SafeFile.safepath_to_string(source)) do |zipfile|
            zipfile.entries.each do |entry|
              # SECURE: TPG 2010-11-1: The path is stripped from the zipfile entry when extracted
              basename = ::File.basename(entry.name)
              zipfile.extract(entry, destination.join(basename)) if entry.file? && basename.match(pattern)
            end
          end

        rescue ::Zip::ZipDestinationFileExistsError
          # I'm going to ignore this and just overwrite the files.
        rescue SecurityError => ex
          raise ex
        rescue ArgumentError => ex
          raise ex
        rescue => ex
          puts ex
        end
      end
    end
  end
end
