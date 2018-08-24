# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class WhereBlock < Block
      def initialize(node)
        super(:Where, node)
      end

      def header
        @header ||= parse_header
      end

      def data
        @data ||= parse_data
      end

      def successors
        @successors ||= [:End].freeze
      end

      private

      def parse_header
        header = []
        header_pipe_node?(children.first, header) || terminal_header_node?(children.first, header)
        header
      end

      def header_pipe_node?(node, header)
        return false if node.nil?

        node.type == :send &&
          node.children.count == 3 &&
          (header_pipe_node?(node.children[0], header) || terminal_header_node?(node.children[0], header)) &&
          node.children[1] == :| &&
          terminal_header_node?(node.children[2], header)
      end

      def terminal_header_node?(node, header)
        return false if node.nil?

        result = node.type == :send &&
          node.children.count == 2 &&
          node.children.first.nil? &&
          node.children.last.is_a?(Symbol)

        raise MalformedError, "Where Block is malformed at location: #{node.loc&.expression || "?"}" unless result

        header << node.children.last if result

        result
      end

      def parse_data
        _header_node, *row_nodes = children
        row_nodes.map do |node|
          data = []
          data_pipe_node?(node, data) || terminal_data_node?(node, data)
          data
        end
      end

      def data_pipe_node?(node, data)
        return false if node.nil?

        node.type == :send &&
          node.children.count == 3 &&
          (data_pipe_node?(node.children[0], data) || terminal_data_node?(node.children[0], data)) &&
          node.children[1] == :| &&
          terminal_data_node?(node.children[2], data)
      end

      def terminal_data_node?(node, data)
        data << node
        true
      end
    end
  end
end
