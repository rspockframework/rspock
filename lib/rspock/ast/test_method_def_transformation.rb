# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/test_method_dstr_transformation'

module RSpock
  module AST
    class TestMethodDefTransformation < ASTTransform::AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :test_index))

      def run(node)
        return node unless node.type == :send && node.children[0].nil? && node.children[1] == :test

        super
      end

      def on_str(node)
        node.updated(:dstr, [TEST_INDEX_AST, node])
      end

      def on_dstr(node)
        TestMethodDstrTransformation.new.run(node)
      end
    end
  end
end
