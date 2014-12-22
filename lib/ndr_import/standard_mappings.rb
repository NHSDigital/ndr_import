# StandardMappings stores the filesystem path to the standard mappings YAML file
class StandardMappings
  # filesystem path is stored as a class level instance variable
  class << self
    # Returns the standard mappings filesystem path
    def fs_path
      if defined?(@fs_path)
        @fs_path
      else
        fail 'StandardMappings not configured!'
      end
    end

    # Takes the path the filesystem_paths.yml file that should be used.
    def configure!(filepath)
      @fs_path = filepath
    end
  end
end
