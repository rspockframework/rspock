# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/then_block_transformation'

module RSpock
  module AST
    class ThenBlockTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::AST::TransformationHelper

      def setup
        @transformation = RSpock::AST::ThenBlockTransformation.new
        @equal_ast = s(:send, 1, :==, 2)
        @not_equal_ast = s(:send, 1, :!=, 2)
      end

      test "#process returns nil when passing nil" do
        actual = @transformation.process(nil)

        assert_nil actual
      end

      test "#process returns input when not an AST node" do
        actual = @transformation.process(123)

        assert_equal 123, actual
      end

      test "#on_send transforms AST into assert_equal when using == where op1 is actual and op2 is expected" do
        actual = @transformation.on_send(@equal_ast)
        expected = s(:send, nil, :assert_equal, 2, 1)

        assert_equal expected, actual
      end

      test "#on_send transforms AST into assert_equal when using != where op1 is actual and op2 is expected" do
        actual = @transformation.on_send(@not_equal_ast)
        expected = s(:send, nil, :refute_equal, 2, 1)

        assert_equal expected, actual
      end

      test "#on_send applies transformation for nested comparisons" do
        node = s(:block, @equal_ast)

        actual = @transformation.on_send(node)
        expected = s(:block, s(:send, nil, :assert_equal, 2, 1))

        assert_equal expected, actual
      end

      test "#on_send returns the same AST if it does not contain a comparison" do
        node = s(:block, s(:send, nil, :assert_equal, 2, 1))

        actual = @transformation.on_send(node)
        expected = s(:block, s(:send, nil, :assert_equal, 2, 1))

        assert_equal expected, actual
      end
    end
  end
end
