# encoding: UTF-8

module NdrImport
  module NonTabular
    # This class behaves like a string and is used instead of the each source line of text.
    # It allows us to contain additional information relating to the use of the line e.g. is
    # the line within a record or for which fields the line has been used to capture a value.
    class Line
      attr_accessor :absolute_line_number,
                    :captured_fields,
                    :captures_values,
                    :in_a_record,
                    :record_line_number,
                    :removed

      def initialize(line)
        @line = line.rstrip
        @in_a_record = false
        @removed = false
        @captured_fields = []
        @captures_values = []
      end

      def =~(other)
        @line =~ other
      end

      def match(*args)
        @line.match(*args)
      end

      def to_s
        @line
      end

      def captured_for(field)
        @captured_fields << field if field && !@captured_fields.include?(field)
      end

      def matches_for(field, value)
        @captures_values << [field, value]
      end
    end
  end
end
