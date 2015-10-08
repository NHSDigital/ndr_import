require 'pdf-reader'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a PDF file handler that returns a single table.
    class Pdf < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        reader = PDF::Reader.new(SafeFile.safepath_to_string(@filename))

        reader.pages.each do |page|
          process_page(page, &block)
        end

      rescue NoMethodError
        raise "Failed to read #{SafeFile.basename(@filename)} as a PDF"
      end

      def process_page(page, &block)
        page.text.split("\n").each do |line|
          block.call(line)
        end
      rescue => e
        raise "Invalid format on page #{page.number} of #{SafeFile.basename(@filename)} " \
              "[#{e.class}: #{e.message}]"
      end
    end

    Registry.register(Pdf, 'pdf')
  end
end
