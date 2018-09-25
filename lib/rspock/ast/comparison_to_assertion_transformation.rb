# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/method_call_to_lvar_transformation'

module RSpock
  module AST
    class ComparisonToAssertionTransformation < ASTTransform::AbstractTransformation
      def initialize(*ignored_method_call_symbols)
        @method_call_transformation = RSpock::AST::MethodCallToLVarTransformation.new(*ignored_method_call_symbols)
      end

      def on_send(node)
        if node.children.count == 3 && node.children[1] == :== && ignored_method_call_node?(node)
          transform_to_assert_equal(node.children[0], node.children[2])
        elsif node.children.count == 3 && node.children[1] == :!= && ignored_method_call_node?(node)
          transform_to_refute_equal(node.children[0], node.children[2])
        else
          node.updated(nil, process_all(node))
        end
      end

      private

      def ignored_method_call_node?(node)
        return false unless node.is_a?(Parser::AST::Node)

        !@method_call_transformation.method_call_node?(node.children[0]) &&
          !@method_call_transformation.method_call_node?(node.children[2])
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
