module NdrImport
  # Raised if incoming data has not ben mapped.
  class UnmappedDataError < StandardError
    attr_reader :keys

    def initialize(keys)
      @keys = keys
      message = "Unmapped data: #{keys.to_sentence}"
      super(message)
    end
  end
end
