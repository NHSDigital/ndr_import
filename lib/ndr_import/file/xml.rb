require 'ndr_support/safe_file'
require 'ndr_import/helpers/file/xml'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a xml file handler that returns a single table.
    class Xml < Base
      include NdrImport::Helpers::File::Xml

      private

      # Iterate through the file, yielding each 'root_node' element in turn.
      def rows(&block)
        return enum_for(:rows) unless block

        doc = read_xml_file(@filename)

        doc.xpath(@options['root_node']).each do |xml_element|
          yield xml_element
        end
      rescue StandardError => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end
    end
    # Not all xml files may want to be registered, so 'xml' is not registered by design.
    Registry.register(Xml, 'xml_table')
  end
end
