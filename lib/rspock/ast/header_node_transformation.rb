# frozen_string_literal: true
require 'rspock/ast/abstract_transformation'

module RSpock
  module AST
    class HeaderNodeTransformation < AbstractTransformation
      def initialize(header)
        @header = header
      end

      def process(node)
        return node unless node.is_a?(Parser::AST::Node)

        super
      end

      def on_send(node)
        return super unless header_node?(node)

        node.updated(:lvar, [node.children[1]])
      end

      private

      def header_node?(node)
        return false if node.nil?

        node.children.count == 2 &&
          node.children[0].nil? &&
          node.children[1].is_a?(Symbol) &&
          @header.include?(node.children[1])
      end
    end
  end
end
