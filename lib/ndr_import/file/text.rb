require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a text file handler that returns a single table.
    class Text < Base
      include UTF8Encoding

      private

      def rows(&block)
        return enum_for(:rows) unless block

        # Encoding:
        #   As we're going to be yielding the lines of the file as it is streamed
        #   (rather than slurped in advance), we need to know which encoding / mode
        #   is going to work in advance.
        #
        path = SafeFile.safepath_to_string(@filename)
        mode = read_mode_for(path)

        # SECURE: TG 13 Oct 2015 SafeFile.safepath_to_string ensures that the path is SafePath.
        ::File.new(path, mode).each { |line| block.call ensure_utf8!(line).chomp }
      rescue => e
        raise "Failed to read #{SafeFile.basename(@filename)} as text [#{e.class}: #{e.message}]"
      end

      # TODO: In Ruby 2.0+, a mode of "rb:bom|utf-16:utf-8" seemed to fix all cases,
      # but this doesn't work on Ruby 1.9.3, which we are currently still supporting.
      # Therefore, we have to test multiple modes in advance, hence #read_mode_for.
      def read_mode_for(trusted_path)
        # These are the read modes we will try, in order:
        modes = ['rb:utf-16:utf-8', 'r:utf-8']

        begin
          ::File.new(trusted_path, modes.first).each { |_line| }
        rescue Encoding::InvalidByteSequenceError
          modes.shift # That one didn't work...
          retry if modes.any?
        end

        modes.first || fail('Unable to determine working stream encoding!')
      end
    end

    Registry.register(Text, 'txt') # TODO: Add 'nontabular'?
  end
end
