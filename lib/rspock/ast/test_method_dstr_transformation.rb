# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class TestMethodDstrTransformation < ASTTransform::AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :_test_index_))

      LINE_NUMBER_AST = s(:begin,
                          s(:lvar, :_line_number_))

      SPACE_STR_AST = s(:str, " ")

      LINE_NUMBER_STR_AST = s(:str, " line ")

      def on_dstr(node)
        children = [*process_all(node), SPACE_STR_AST, TEST_INDEX_AST, LINE_NUMBER_STR_AST, LINE_NUMBER_AST]
        node.updated(nil, children)
      end
    end
  end
end
