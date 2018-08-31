# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class TestMethodDstrTransformation < ASTTransform::AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :test_index))

      def on_dstr(node)
        children = [TEST_INDEX_AST, *process_all(node)]
        node.updated(nil, children)
      end
    end
  end
end
