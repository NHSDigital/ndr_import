require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a text file handler that returns a single table.
    class Text < Base
      private

      def rows(&block)
        
        return enum_for(:rows) unless block

        # SECURE: TG 13 Oct 2015 SafeFile.safepath_to_string ensures that the path is SafePath.
        # TODO: SafeFile.new does not support the 'rt' switches
        ::File.new(SafeFile.safepath_to_string(@filename), 'rt').each do |line|
          block.call(line.sub(/\n\z/, ''))
        end

      rescue => e
        raise "Failed to read #{SafeFile.basename(@filename)} as text " \
              "[#{e.class}: #{e.message}]"
      end
    end

    Registry.register(Text, 'txt') # TODO: Add 'nontabular'?
  end
end
