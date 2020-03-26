require 'shellwords'

require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML streaming functionality, to support more performant handling
      # of large files by Nokogiri. Uses the `XML::Reader` API, and maintains a temporary
      # DOM as the XML is streamed to allow XPath querying from the root node.
      #
      # If the system has `iconv` available, will attempt to verify the encoding of the
      # file being read externally, so it can be streamed in to Ruby. Otherwise, will load
      # the raw data in to check the encoding, but still stream it through Nokogiri's parser.
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

        # Object to track state as the XML is iterated over, and detect
        # when an element of interest is entered.
        class Cursor
          # wrapper to hold a representation of each element we descent into:
          StackItem = Struct.new(:name, :attrs, :empty)

          def initialize(xpath)
            @xpath = xpath
            @stack = []
            @match_depth = nil
          end

          # Has this cursor already passed inside a similar node?
          def in?(node)
            @stack.detect { |item| item.name == node.name }
          end

          def enter(node)
            @stack.push StackItem.new(node.name, node.attributes, node.empty_element?)
          end

          def leave(_node)
            @stack.pop
            @match_depth = nil if @match_depth && @stack.length < @match_depth
          end

          # Does the element that the cursor is currently on match what
          # is being looked for?
          def matches?
            # Can't match again if we're inside a match already:
            return false if @matched_depth

            match = current_stack_match?

            # "empty element" matches are yielded immediately, without
            # tagging the stack as having matched, because there won't
            # be an equivalent closing tag to end the match with later.
            if in_empty_element?
              @stack.pop
            elsif match
              @match_depth = @stack.length
            end

            match
          end

          private

          def in_empty_element?
            @stack.last.empty
          end

          # Does the current state of the stack mean we've met the xpath
          # criteria? Must be an exact match, not just matching a parent
          # element in the DOM.
          def current_stack_match?
            parent_stack = @stack[0..-2]

            return false unless dom_stubs[@stack].at_xpath(@xpath)

            parent_stack.empty? || !dom_stubs[parent_stack].at_xpath(@xpath)
          end

          # A cached collection of DOM fragments, to represent the structure
          # necessary to use xpath to descend into the main document's DOM.
          def dom_stubs
            @dom_stubs ||= Hash.new do |hash, items|
              hash[items.dup] = Nokogiri::XML::Builder.new do |dom|
                add_items_to_dom(dom, items.dup)
              end.doc
            end
          end

          # Helper to recursively build XML fragment.
          def add_items_to_dom(dom, items)
            item = items.shift
            dom.send(item.name, item.attrs) do
              add_items_to_dom(dom, items) if items.any?
            end
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

          with_encoding_check(safe_path) do |stream, encoding|
            stream_xml_nodes(stream, xpath, encoding, &block)
          end
        end

        private

        # We need to ensure the raw data is UTF8 before we start streaming
        # it with nokogiri. If we can do an external check, great. Otherwise,
        # we need to slurp and convert the raw data before presenting it.
        def with_encoding_check(safe_path)
          forced_encoding = nil

          stream = ::File.open(SafeFile.safepath_to_string(safe_path))

          unless external_utf8_check?(safe_path)
            stream = StringIO.new ensure_utf8!(stream.read)
            forced_encoding = 'UTF8'
          end

          yield stream, forced_encoding
        end

        # Use iconv, if available, to check raw data encoding:
        def external_utf8_check?(safe_path)
          iconv = system('command -v iconv > /dev/null 2>&1')
          return false unless iconv

          path = SafeFile.safepath_to_string(safe_path)
          system("iconv -f UTF-8 #{Shellwords.escape(path)} > /dev/null 2>&1")
        end

        def stream_xml_nodes(io, node_xpath, encoding = nil)
          # Track nesting as the cursor moves through the document:
          cursor = Cursor.new(node_xpath)

          # If markup isn't well-formed, try to work around it:
          options = Nokogiri::XML::ParseOptions::RECOVER
          reader  = Nokogiri::XML::Reader(io, nil, encoding, options)

          reader.each do |node|
            case node.node_type
            when Nokogiri::XML::Reader::TYPE_ELEMENT # "opening tag"
              raise NestingError, node if cursor.in?(node)

              cursor.enter(node)
              next unless cursor.matches?

              # The xpath matched - construct a DOM fragment to yield back:
              element = Nokogiri::XML(node.outer_xml).at("./#{node.name}")
              yield element
            when Nokogiri::XML::Reader::TYPE_END_ELEMENT # "closing tag"
              cursor.leave(node)
            end
          end
        end
      end
    end
  end
end
