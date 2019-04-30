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

        doc = if @options.key?(:file_password)
                decrypted_docx_document(@filename, @options[:file_password])
              else
                ::Docx::Document.open(SafeFile.safepath_to_string(@filename))
              end

        doc.paragraphs.each do |p|
          yield(p.to_s)
        end
      rescue StandardError => e
        raise("#{SafeFile.basename(@filename)} [#{e.class}: #{e.message}]")
      end

      # This method returns the Docx::Document of a password protected docx file
      def decrypted_docx_document(encrypted_path, password)
        Tempfile.create(['decrypted', '.docx']) do |file|
          file.write(decrypted_file_string(encrypted_path, password))
          file.close

          return ::Docx::Document.open(file.path)
        end
      end
    end

    Registry.register(Docx, 'docx')
  end
end
