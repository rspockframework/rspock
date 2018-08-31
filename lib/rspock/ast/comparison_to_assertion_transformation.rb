# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class ComparisonToAssertionTransformation < ASTTransform::AbstractTransformation
      def on_send(node)
        if node.children.count == 3 && node.children[1] == :==
          transform_to_assert_equal(node.children[0], node.children[2])
        elsif node.children.count == 3 && node.children[1] == :!=
          transform_to_refute_equal(node.children[0], node.children[2])
        else
          node.updated(nil, process_all(node))
        end
      end

      private

      def transform_to_assert_equal(lhs, rhs)
        s(:send, nil, :assert_equal, rhs, lhs)
      end

      def transform_to_refute_equal(lhs, rhs)
        s(:send, nil, :refute_equal, rhs, lhs)
      end
    end
  end
end
