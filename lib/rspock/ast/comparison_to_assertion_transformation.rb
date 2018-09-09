# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/test_index_nodes_transformation'

module RSpock
  module AST
    class ComparisonToAssertionTransformation < ASTTransform::AbstractTransformation
      def on_send(node)
        if node.children.count == 3 && node.children[1] == :== && not_test_index_operands(node)
          transform_to_assert_equal(node.children[0], node.children[2])
        elsif node.children.count == 3 && node.children[1] == :!= && not_test_index_operands(node)
          transform_to_refute_equal(node.children[0], node.children[2])
        else
          node.updated(nil, process_all(node))
        end
      end

      private

      def not_test_index_operands(node)
        return false unless node.is_a?(Parser::AST::Node)

        !test_index_node?(node.children[0]) && !test_index_node?(node.children[2])
      end

      def test_index_node?(node)
        test_index_nodes_transformation.test_index_node?(node)
      end

      def test_index_nodes_transformation
        @test_index_nodes_transformation ||= RSpock::AST::TestIndexNodesTransformation.new
      end

      def transform_to_assert_equal(lhs, rhs)
        s(:send, nil, :assert_equal, rhs, lhs)
      end

      def transform_to_refute_equal(lhs, rhs)
        s(:send, nil, :refute_equal, rhs, lhs)
      end
    end
  end
end
