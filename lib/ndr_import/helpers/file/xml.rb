require 'ndr_import/xml/control_char_escaper'
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

          require 'nokogiri'

          doc = nil

          escaping_control_chars_if_necessary(preserve_control_chars, file_data) do
            doc = Nokogiri::XML(file_data, &:huge)
            doc.encoding = 'UTF-8'
            emulate_strict_mode_fatal_check!(doc)
          end

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

        def escaping_control_chars_if_necessary(preserve_control_chars, file_data)
          return yield if preserve_control_chars

          tried_escaping = false
          begin
            yield
          rescue Nokogiri::XML::SyntaxError => e
            raise e if tried_escaping

            NdrImport::Xml::ControlCharEscaper.new(file_data).escape!
            tried_escaping = true
            retry
          end
        end
      end
    end
  end
end
