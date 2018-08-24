# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/expect_block'

module RSpock
  module AST
    class ExpectBlockTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::AST::TransformationHelper

      def setup
        @block = RSpock::AST::ExpectBlock.new(nil)
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

      test "#to_children_ast returns transformed children when comparing with == or !=" do
        @block.children = [
          s(:send, 1, :==, 2),
          s(:send, 1, :!=, 2)
        ]

        actual = @block.to_children_ast
        expected = [
          s(:send, nil, :assert_equal, 2, 1),
          s(:send, nil, :refute_equal, 2, 1)
        ]

        assert_equal expected, actual
      end
    end
  end
end
