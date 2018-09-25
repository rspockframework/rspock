# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/method_call_to_lvar_transformation'

module RSpock
  module AST
    class MethodCallToLVarTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      test "#run transforms passed symbol calls into lvar" do
        transformation = RSpock::AST::MethodCallToLVarTransformation.new(:_test_index_)

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :_test_index_),
                s(:send, nil, :b),
                s(:send, nil, :c))

        actual = transformation.run(ast)

        expected = s(:begin,
                     s(:send, nil, :a),
                     s(:lvar, :_test_index_),
                     s(:send, nil, :b),
                     s(:send, nil, :c))

        assert_equal expected, actual
      end

      test "#run does not transform any method calls if no symbols were passed" do
        transformation = RSpock::AST::MethodCallToLVarTransformation.new

        ast = s(:begin,
                s(:send, nil, :a),
                s(:send, nil, :_test_index_),
                s(:send, nil, :b),
                s(:send, nil, :c))

        actual = transformation.run(ast)

        expected = s(:begin,
                     s(:send, nil, :a),
                     s(:send, nil, :_test_index_),
                     s(:send, nil, :b),
                     s(:send, nil, :c))

        assert_equal expected, actual
      end
    end
  end
end
