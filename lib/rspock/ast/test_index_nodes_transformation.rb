# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class TestIndexNodesTransformation < ASTTransform::AbstractTransformation
      TEST_INDEX_SEND_NODE = s(:send, nil, :test_index)

      def on_send(node)
        return super unless test_index_node?(node)

        node.updated(:lvar, [node.children[1]])
      end

      def test_index_node?(node)
        node == TEST_INDEX_SEND_NODE
      end
    end
  end
end
