require 'ndr_support/utf8_encoding'

module NdrImport
  module Xml
    # A class to remove control characters, and XML entities representing them
    class ControlCharEscaper
      include UTF8Encoding

      # Matches XML character reference entities
      CHARACTER_REFERENCES = /&#(?:(?<decimal>\d+)|x(?<hex>\h+));/.freeze

      attr_reader :data

      def initialize(data)
        @data = data
      end

      def escape!
        unescape_control_char_references!(data)
        escape_control_chars!(data)
      end

      private

      def unescape_control_char_references!(data)
        data.gsub!(CHARACTER_REFERENCES) do |reference|
          char = try_to_extract_char_from(Regexp.last_match)

          if char&.match?(CONTROL_CHARACTERS)
            escape_control_chars!(char)
          else
            reference
          end
        end
      end

      def try_to_extract_char_from(match)
        if match.nil?
          nil
        elsif match[:decimal]
          match[:decimal].to_i(10).chr
        elsif match[:hex]
          match[:hex].to_i(16).chr
        end
      rescue RangeError
        # Return everything if the match was against junk:
        match.to_s
      end
    end
  end
end
