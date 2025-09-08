require 'pdf-reader'

module NdrImport
  # test
  # PDF AcroForm reader using the pdf-reader gem
  class AcroFormReader < ::PDF::Reader
    def fields_hash
      fields = {}
      fields_from(acroform[:Fields]).each do |field|
        field_name = field[:T]
        unless field[:Subtype] == :Widget || field.key?(:Kids)
          raise "Widgets or Radio boxes expected, found a #{field[:Subtype].inspect}"
        end
        raise "Non-unique column name #{field_name}" if fields.key?(field_name)
        fields[field_name] = field[:V]
      end
      fields
    end

    private

    def acroform
      @objects.deref(root[:AcroForm])
    end

    def fields_from(refs)
      Array(refs).flat_map do |ref|
        value = @objects[ref]
        # PDF has its own Hash class
        value.is_a?(::Hash) ? value : fields_from(value)
      end
    end
  end
end
