# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class HeaderNodesTransformation < ASTTransform::AbstractTransformation
      def initialize(header)
        @header = header
      end

      def run(node)
        return node if @header.nil? || @header.empty?

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
