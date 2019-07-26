require 'ndr_support/safe_file'
require 'ndr_support/utf8_encoding'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML streaming functionality to unified importers.
      module XmlStreaming
        private

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

        def stream_xml_nodes(file_data, node_xpath, &block)
          require 'nokogiri'

          # Track nesting as the cursor moves through the document:
          stack       = []
          match_depth = nil

          Nokogiri::XML::Reader(file_data).each do |node|
            case node.node_type
            when 1 then # "start element"
              stack.push [node.name, node.attributes]

              if match_depth || !stub_match?(stack, node_xpath)
                stack.pop if node.empty_element?
                next
              end

              # "empty element" matches are yielded immediately, without
              # tagging the stack as having matched, because there won't
              # be an equivalent closing tag to end the match with later.
              if node.empty_element?
                stack.pop
              else
                match_depth = stack.length
              end

              block.call Nokogiri::XML(node.outer_xml).at("./#{node.name}")
            when 15 then # "end element"
              stack.pop
              match_depth = nil if match_depth && stack.length < match_depth
            end
          end
        end
      end
    end
  end
end
