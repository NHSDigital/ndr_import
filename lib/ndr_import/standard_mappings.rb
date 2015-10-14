module NdrImport
  # NdrImport::StandardMappings stores the standard mappings hash
  class StandardMappings
    # mappings are stored as a class level instance variable
    class << self
      # Gets the standard mappings
      def mappings
        if defined?(@standard_mappings)
          @standard_mappings
        else
          fail 'NdrImport::StandardMappings not configured!'
        end
      end

      # Sets the standard mappings
      def mappings=(hash)
        fail ArgumentError unless hash.is_a?(Hash)

        @standard_mappings = hash
      end
    end
  end
end
