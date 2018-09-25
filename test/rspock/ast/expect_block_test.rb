# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/expect_block'

module RSpock
  module AST
    class ExpectBlockTest < Minitest::Test
      extend RSpock::Declarative
      include ASTTransform::TransformationHelper

      def setup
        @block = RSpock::AST::ExpectBlock.new(nil)
      end

      test "#node_container? returns true by default" do
        assert_equal true, @block.node_container?
      end

      test "#successors returns the correct successors" do
        assert_equal [:Cleanup, :Where, :End], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#type is :Then" do
        assert_equal :Expect, @block.type
      end

      test "#children returns transformed children when comparing with == or !=" do
        @block << s(:send, 1, :==, 2)
        @block << s(:send, 1, :!=, 2)

        actual = @block.children
        expected = [
          s(:send, nil, :assert_equal, 2, 1),
          s(:send, nil, :refute_equal, 2, 1)
        ]

        assert_equal expected, actual
      end

      test "#children ignores _test_index_ and line_number comparisons when comparing with == or !=" do
        test_index_ast = s(:send, 1, :==, s(:send, nil, :_test_index_))
        line_number_ast = s(:send, 1, :!=, s(:send, nil, :line_number))

        @block << test_index_ast
        @block << line_number_ast

        actual = @block.children
        expected = [test_index_ast, line_number_ast]

        assert_equal expected, actual
      end
    end
  end
end
