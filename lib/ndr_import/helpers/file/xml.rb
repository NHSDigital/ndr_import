require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML functionality to unified importers.
      module Xml
        include UTF8Encoding

        private

        def read_xml_file(path)
          file_data = SafeFile.new(path).read

          require 'nokogiri'

          Nokogiri::XML(ensure_utf8! file_data).tap { |doc| doc.encoding = 'UTF-8' }
        end
      end
    end
  end
end
