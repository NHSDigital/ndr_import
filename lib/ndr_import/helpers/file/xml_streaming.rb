require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML streaming functionality to unified importers.
      module XmlStreaming
        # Base error for all streaming-specific issues.
        class Error < StandardError; end

        # Raised if nested tags are accounted which the streaming approach cannnot handle.
        class NestingError < Error
          def initialize(node)
            super <<~STR
              Element '#{node.name}' was found nested inside another of the same type.
              This is not accessible, and a known limitation of XmlStreaming.
            STR
          end
        end

        # Object to track state as the XML is iterated over
        class Cursor
          def initialize(xpath)
            @xpath = xpath
            @stack = []
            @match_depth = nil
          end

          def in?(node)
            @stack.assoc(node.name)
          end

          def enter(node)
            @stack.push [node.name, node.attributes]
          end

          def leave(_node)
            @stack.pop
            @match_depth = nil if @match_depth && @stack.length < @match_depth
          end

          def attempt_match(ref, node)
            # FIXME: neither argument should be required.
            match = ref.send(:stub_match?, @stack, @xpath)

            # "empty element" matches are yielded immediately, without
            # tagging the stack as having matched, because there won't
            # be an equivalent closing tag to end the match with later.
            if node.empty_element?
              @stack.pop
            elsif match
              @match_depth = @stack.length
            end

            return match
          end

          def unmatched?
            @matched_depth.nil?
          end
        end

        include UTF8Encoding

        # Streams the contents of the given `safe_path`, and yields
        # each element matching `xpath` as they're found.
        #
        # In the case of dodgy encoding, may fall back to slurping the
        # file, but will still use stream parsing for XML.
        def each_node(safe_path, xpath, &block)
          return enum_for(:each_node, safe_path, xpath) unless block

          require 'nokogiri'

          file = ::File.open(SafeFile.safepath_to_string(safe_path))

          with_encoding_retry(file) do |stream, encoding|
            stream_xml_nodes(stream, xpath, encoding, &block)
          end
        end

        private

        # By default, let Nokogiri try and sort out any encoding issues,
        # but if necessary "go nuclear" - slurp the stream and force it to UTF-8.
        def with_encoding_retry(stream)
          forced_encoding = nil

          begin
            yield stream, forced_encoding
          rescue Nokogiri::XML::SyntaxError => e
            raise e if forced_encoding
            raise e unless e.message =~ /not proper UTF-8, indicate encoding/

            stream.rewind
            stream = StringIO.new ensure_utf8!(stream.read)
            forced_encoding = 'UTF8'

            retry
          end
        end

        def add_nodes(xml, nodes)
          name, attributes = *nodes.shift
          xml.send(name, attributes) { add_nodes(xml, nodes) if nodes.any? }
        end

        def stubs
          # Stubs at each nesting, to apply xpath to:
          @stubs ||= Hash.new do |hash, nodes|
            hash[nodes.dup] = Nokogiri::XML::Builder.new do |xml|
              add_nodes(xml, nodes.dup)
            end.doc
          end
        end

        def stub_match?(stack, node_xpath)
          parent_stack = stack[0..-2]

          # Only true if the xpath matches the stack...
          return false unless stubs[stack].at_xpath(node_xpath)

          # ...and the entire stack:
          parent_stack.empty? || !stubs[parent_stack].at_xpath(node_xpath)
        end

        def stream_xml_nodes(io, node_xpath, encoding = nil, &block)
          # Track nesting as the cursor moves through the document:
          cursor = Cursor.new(node_xpath)

          # If markup isn't well-formed, work around it and record errors
          # for later:
          options = Nokogiri::XML::ParseOptions::RECOVER
          reader  = Nokogiri::XML::Reader(io, nil, encoding, options)

          reader.each do |node|
            case node.node_type
            when 1 then # "start element"
              raise NestingError.new(node) if cursor.in?(node)

              cursor.enter(node)

              if cursor.unmatched? && cursor.attempt_match(self, node)
                block.call Nokogiri::XML(node.outer_xml).at("./#{node.name}")
              end
            when 15 then # "end element"
              cursor.leave(node)
            end
          end
        end
      end
    end
  end
end
