# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/test_method_dstr_transformation'

module RSpock
  module AST
    # Appends the data row's index and source line to a Where-driven test's name. The values arrive through
    # internal block parameters on the row iterator (see TestMethodTransformation#build_where_args) and surface in
    # the test NAME only: the name is what makes identical data rows unique and what the -n selector matches to
    # isolate a row. They are deliberately not exposed as test-scope variables.
    class TestMethodDefTransformation < ASTTransform::AbstractTransformation
      ROW_INDEX_ARG = :__rspock_row_index__
      ROW_LINE_ARG = :__rspock_row_line__

      ROW_INDEX_AST = s(:begin, s(:lvar, ROW_INDEX_ARG))
      ROW_LINE_AST = s(:begin, s(:lvar, ROW_LINE_ARG))
      LINE_NUMBER_STR_AST = s(:str, " line ")

      def run(node)
        return node unless node.type == :send && node.children[0].nil? && node.children[1] == :test

        super
      end

      def on_str(node)
        merged = s(:str, "#{node.children[0]} ")
        node.updated(:dstr, [merged, ROW_INDEX_AST, LINE_NUMBER_STR_AST, ROW_LINE_AST])
      end

      def on_dstr(node)
        TestMethodDstrTransformation.new.run(node)
      end
    end
  end
end
