require 'msworddoc-extractor'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a Word document file handler that returns a single table.
    # currently only works on .doc (97-2003), not.docx
    class Word < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        doc = MSWordDoc::Extractor.load(SafeFile.safepath_to_string(@filename))

        doc.whole_contents.split("\n").each do |line|
          block.call(line)
        end

      rescue => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end
    end

    Registry.register(Word, 'doc') # TODO: Add 'word'?
  end
end
