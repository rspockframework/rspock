# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class MethodCallToLVarTransformation < ASTTransform::AbstractTransformation
      def initialize(*method_symbols)
        @method_call_nodes = method_symbols.map { |method_sym|
          s(:send, nil, method_sym)
        }
      end

      def on_send(node)
        return super unless method_call_node?(node)

        node.updated(:lvar, [node.children[1]])
      end

      def method_call_node?(node)
        @method_call_nodes.include?(node)
      end
    end
  end
end
