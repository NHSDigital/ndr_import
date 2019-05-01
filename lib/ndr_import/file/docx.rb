require 'docx'
require 'ndr_support/safe_file'
require_relative 'office_file_helper'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a modern Word document file handler that returns a single table.
    # It only works on .docx documents
    class Docx < Base
      include OfficeFileHelper

      private

      def rows(&block)
        return enum_for(:rows) unless block

        send(@options.key?(:file_password) ? :decrypted_path : :unencrypted_path) do |path|
          doc = ::Docx::Document.open(path)

          doc.paragraphs.each do |p|
            yield(p.to_s)
          end

          doc.zip.close
        end
      rescue StandardError => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end

      # This method returns the path to the temporary, decrypted file
      def decrypted_path
        Tempfile.create(['decrypted', '.docx']) do |file|
          file.write(decrypted_file_string(@filename, @options[:file_password]))
          file.close

          yield file.path
        end
      end

      # This method returns the safepath to the unencrypted docx file
      def unencrypted_path
        yield SafeFile.safepath_to_string(@filename)
      end
    end

    Registry.register(Docx, 'docx')
  end
end
