# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/test_index_nodes_transformation'

module RSpock
  module AST
    class TestIndexNodesTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      test "#run transforms test_index calls into lvar" do
        transformation = RSpock::AST::TestIndexNodesTransformation.new

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :test_index),
                s(:send, nil, :b),
                s(:send, nil, :c))

        actual = transformation.run(ast)

        expected = s(:begin,
                     s(:send, nil, :a),
                     s(:lvar, :test_index),
                     s(:send, nil, :b),
                     s(:send, nil, :c))

        assert_equal expected, actual
      end
    end
  end
end
