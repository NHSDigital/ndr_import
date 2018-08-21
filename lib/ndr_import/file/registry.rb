require 'ndr_support/safe_file'

module NdrImport
  module File
    # This mixin adds table enumeration functionality to importers.
    module Registry
      class <<self
        attr_accessor :handlers

        def register(klass, *formats)
          @handlers ||= {}

          formats.each do |format|
            @handlers[format] = klass
          end
        end

        def unregister(*formats)
          formats.each do |format|
            @handlers.delete(format)
          end
        end

        def files(filename, options = {}, &block)
          return enum_for(:files, filename, options) unless block

          klass_factory(filename, nil, nil, options).files(&block)
        end

        def tables(filename, format = nil, delimiter = nil, options = {}, &block)
          return enum_for(:tables, filename, format, delimiter, options) unless block

          klass_factory(filename, format, delimiter, options).tables(&block)
        end

        private

        def klass_factory(filename, format, delimiter, options)
          format ||= SafeFile.extname(filename).delete('.').downcase
          klass = Registry.handlers[format]
          return klass.new(filename, format, delimiter, options) if klass
          raise "Error: Unknown file format #{format.inspect}"
        end
      end
    end
  end
end

require_relative 'all'
