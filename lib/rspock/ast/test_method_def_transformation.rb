# frozen_string_literal: true
require 'rspock/ast/abstract_transformation'
require 'rspock/ast/test_method_dstr_transformation'

module RSpock
  module AST
    class TestMethodDefTransformation < AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :test_index))

      def run(node)
        raise unless node.type == :send && node.children[0].nil? && node.children[1] == :test

        process(node)
      end

      def process(node)
        return node unless node.is_a?(Parser::AST::Node)

        super
      end

      def on_str(node)
        node.updated(:dstr, [TEST_INDEX_AST, node])
      end

      def on_dstr(node)
        TestMethodDstrTransformation.new.process(node)
      end
    end
  end
end
