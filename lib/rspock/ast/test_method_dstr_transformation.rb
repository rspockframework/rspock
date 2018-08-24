# frozen_string_literal: true
require 'rspock/ast/abstract_transformation'

module RSpock
  module AST
    class TestMethodDstrTransformation < AbstractTransformation
      TEST_INDEX_AST = s(:begin,
                         s(:lvar, :test_index))

      def on_dstr(node)
        children = [TEST_INDEX_AST, *process_all(node)]
        node.updated(nil, children)
      end
    end
  end
end
