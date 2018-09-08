# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class TestIndexNodesTransformation < ASTTransform::AbstractTransformation
      def on_send(node)
        return super unless test_index_node?(node)

        node.updated(:lvar, [node.children[1]])
      end

      private

      def test_index_node?(node)
        return false if node.nil?

        node.children.count == 2 &&
          node.children[0].nil? &&
          node.children[1] == :test_index
      end
    end
  end
end
