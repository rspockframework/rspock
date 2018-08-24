# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/header_nodes_transformation'

module RSpock
  module AST
    class HeaderNodesTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      test "#run transforms headers only into lvar" do
        transformation = RSpock::AST::HeaderNodesTransformation.new([:a, :b, :c])

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :b),
                s(:send, nil, :c),
                s(:send, nil, :d))

        actual = transformation.run(ast)

        expected = s(:begin,
                     s(:lvar, :a),
                     s(:lvar, :b),
                     s(:lvar, :c),
                     s(:send, nil, :d))

        assert_equal expected, actual
      end

      test "#run returns the same node if header is empty" do
        transformation = RSpock::AST::HeaderNodesTransformation.new([])

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :b),
                s(:send, nil, :c),
                s(:send, nil, :d))

        actual = transformation.run(ast)

        assert_same ast, actual
      end

      test "#run returns the same node if header is nil" do
        transformation = RSpock::AST::HeaderNodesTransformation.new(nil)

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :b),
                s(:send, nil, :c),
                s(:send, nil, :d))

        actual = transformation.run(ast)

        assert_same ast, actual
      end
    end
  end
end
