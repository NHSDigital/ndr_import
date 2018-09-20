module NdrImport
  module File
    # This is a stub file handler for files with file extensions that aren't in the registry.
    class UnregisteredFiletype < Base
      def tables
        raise "Error: Unknown file format #{@format.inspect}"
      end
    end
  end
end
