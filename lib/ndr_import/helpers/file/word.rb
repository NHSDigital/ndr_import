require 'ndr_support/safe_file'

module NdrImport
  module Helpers
    module File
      # This mixin adds Word document functionality to unified importers.
      # It provides a file reader method.
      # currently only works on .doc (97-2003), not.docx
      module Word
        private

        def read_word_file(path)
          require 'msworddoc-extractor'
          lines = []
          begin
            doc = MSWordDoc::Extractor.load(SafeFile.safepath_to_string(path))

            lines.concat doc.whole_contents.split("\n")
          rescue => e
            raise("#{SafeFile.basename(path)} [#{e.class}: #{e.message}]")
          end
          lines
        end
      end
    end
  end
end
