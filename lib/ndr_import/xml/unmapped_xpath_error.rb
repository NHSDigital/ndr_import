module NdrImport
  module Xml
    # Raised if an unmapped xpath is identified
    class UnmappedXpathError < StandardError
      attr_reader :missing_xpaths

      def initialize(missing_xpaths)
        @missing_xpaths = missing_xpaths
        message         = "Unmapped xpath(s): #{missing_xpaths}"

        super(message)
      end
    end
  end
end
