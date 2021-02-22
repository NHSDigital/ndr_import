require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML functionality to unified importers.
      module Xml
        include UTF8Encoding

        private

        # By default, escapes any control characters found in the XML
        # - their use is forbidden in XML 1.0, and highly discouraged
        # in XML 1.1; any found are most likely to be erroneous.
        def read_xml_file(path, preserve_control_chars: false)
          file_data = ensure_utf8!(SafeFile.read(path))
          escape_xml_control_chars!(file_data) unless preserve_control_chars

          require 'nokogiri'

          doc = Nokogiri::XML(file_data, &:huge)
          doc.encoding = 'UTF-8'
          emulate_strict_mode_fatal_check!(doc)

          doc
        end

        # Nokogiri can use give a `STRICT` parse option to libxml, but our friendly
        # handling of muddled encodings causes XML explicitly declared as something
        # other than UTF-8 to fail (because it has been recoded to UTF-8 by the
        # time it is given to Nokogiri / libxml).
        # This raises a SyntaxError if strict mode would have found any other
        # (fatal) issues with the document.
        def emulate_strict_mode_fatal_check!(document)
          # We let slide any warnings about xml declared as one of our
          # auto encodings, but parsed as UTF-8:
          encoding_pattern = AUTO_ENCODINGS.map { |name| Regexp.escape(name) }.join('|')
          encoding_warning = /Document labelled (#{encoding_pattern}) but has UTF-8 content\z/
          fatal_errors     = document.errors.select do |error|
            error.fatal? && (encoding_warning !~ error.message)
          end

          return unless fatal_errors.any?

          raise Nokogiri::XML::SyntaxError, <<~MSG
            The file had #{fatal_errors.length} fatal error(s)!"
            #{fatal_errors.join("\n")}
          MSG
        end

        # In place, escape out any control chars that would cause
        # libxml to crash. Very few are allowable in XML 1.0, and
        # remain heavily discouraged in XML 1.1.
        def escape_xml_control_chars!(data)
          escape_control_chars!(data)
        end
      end
    end
  end
end
