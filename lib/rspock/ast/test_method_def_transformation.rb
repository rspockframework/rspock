# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/test_method_dstr_transformation'

module RSpock
  module AST
    class TestMethodDefTransformation < ASTTransform::AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :_test_index_))

      LINE_NUMBER_AST = s(:begin,
                         s(:lvar, :_line_number_))

      SPACE_STR_AST = s(:str, " ")

      LINE_NUMBER_STR_AST = s(:str, " line ")

      def run(node)
        return node unless node.type == :send && node.children[0].nil? && node.children[1] == :test

        super
      end

      def on_str(node)
        node.updated(:dstr, [node, SPACE_STR_AST, TEST_INDEX_AST, LINE_NUMBER_STR_AST, LINE_NUMBER_AST])
      end

      def on_dstr(node)
        TestMethodDstrTransformation.new.run(node)
      end
    end
  end
end
