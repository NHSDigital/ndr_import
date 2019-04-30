require 'ooxml_decrypt'

module NdrImport
  module File
    # This mixin provides helper methods of MS Office files
    module OfficeFileHelper
      private

      # This method decrypts a (modern) password protected MS Office document
      # returning a String of the decrypted file
      def decrypted_file_string(path, password)
        # Ensure password is a binary representation of a UTF-16LE string
        # e.g. 'password' should be represented as "p\0\a\s\0[...]"
        password = password.encode('utf-16le').bytes.pack('c*').encode('binary')

        OoxmlDecrypt::EncryptedFile.decrypt(SafeFile.safepath_to_string(path), password)
      end
    end
  end
end
