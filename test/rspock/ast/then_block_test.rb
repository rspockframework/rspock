# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/then_block'

module RSpock
  module AST
    class ThenBlockTest < Minitest::Test
      extend RSpock::Declarative
      include ASTTransform::TransformationHelper

      INTERACTION_NODE = s(:send, s(:int, 1), :*, s(:send, :receiver, :message))

      def setup
        @block = RSpock::AST::ThenBlock.new(nil)
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
        assert_equal :Then, @block.type
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

      test "#children ignores _test_index_ and _line_number_ comparisons when comparing with == or !=" do
        test_index_ast = s(:send, 1, :==, s(:send, nil, :_test_index_))
        line_number_ast = s(:send, 1, :!=, s(:send, nil, :_line_number_))

        @block << test_index_ast
        @block << line_number_ast

        actual = @block.children
        expected = [test_index_ast, line_number_ast]

        assert_equal expected, actual
      end

      test "#children ignores interaction nodes" do
        @block << s(:send, 1, :==, 2)
        @block << INTERACTION_NODE

        actual = @block.children
        expected = [
          s(:send, nil, :assert_equal, 2, 1),
        ]

        assert_equal expected, actual
      end

      test "#interactions returns transformed interaction nodes" do
        @block << s(:send, 1, :==, 2)
        @block << INTERACTION_NODE

        actual = @block.interactions
        expected = [
          s(:send,
            s(:send,
              :receiver,
              :expects,
              s(:sym, :message)
            ),
            :times,
            s(:int, 1)
          )
        ]

        assert_equal expected, actual
      end
    end
  end
end
