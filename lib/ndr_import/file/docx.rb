require 'docx'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a modern Word document file handler that returns a single table.
    # It only works on .docx documents
    class Docx < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        doc = ::Docx::Document.open(SafeFile.safepath_to_string(@filename))

        doc.paragraphs.each do |p|
          yield(p.to_s)
        end
      rescue StandardError => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end
    end

    Registry.register(Docx, 'docx')
  end
end
