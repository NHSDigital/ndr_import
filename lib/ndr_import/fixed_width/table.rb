require 'ndr_import/table'

module NdrImport
  module FixedWidth
    # This class maintains the state of a fixed width table mapping and encapsulates
    # the logic required to transform a table of data into "records". Particular
    # attention has been made to use enumerables throughout to help with the
    # transformation of large quantities of data.
    class Table < ::NdrImport::Table
      # This method transforms an incoming line of fixed wwidrh data by applying
      # each of the klass masked mappings to the line and yielding the klass
      # and fields for each mapped klass.
      def transform_line(line, index)
        return enum_for(:transform_line, line, index) unless block_given?

        masked_mappings.each do |klass, klass_mappings|
          line = fixed_width_columns(line, klass_mappings)
          fields = mapped_line(line, klass_mappings)
          next if fields[:skip].to_s == 'true'.freeze
          yield(klass, fields, index)
        end
      end
    end
  end
end
