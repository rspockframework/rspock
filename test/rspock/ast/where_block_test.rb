# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'ast_transform/transformation_helper'
require 'rspock/ast/where_block'

module RSpock
  module AST
    class WhereBlockTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      def setup
        @block = RSpock::AST::WhereBlock.new(nil)
      end

      test "#successors returns the correct successors" do
        assert_equal [:End], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#type is :End" do
        assert_equal :Where, @block.type
      end

      test "#header with a single send ast node returns that node's symbol" do
        @block.children << s(:send, nil, :a)

        assert_equal [:a], @block.header
      end

      test "#header separated by pipes returns each node's symbol" do
        @block.children << s(:send,
                             s(:send,
                               s(:send, nil, :a), :|, s(:send, nil, :b)
                             ),
                             :|, s(:send, nil, :c))

        assert_equal [:a, :b, :c], @block.header
      end

      test "#header with a single send ast node must be a header node" do
        @block.children << s(:str, "potato")

        assert_raises RSpock::AST::WhereBlock::MalformedError do
          @block.header
        end
      end

      test "#header terminal nodes must be header nodes" do
        @block.children << s(:send,
                             s(:str, "potato"), :|, s(:send, nil, :b))

        assert_raises RSpock::AST::WhereBlock::MalformedError do
          @block.header
        end
      end

      test "#data with a single data node returns that data node" do
        @block.children << s(:send, nil, :a)
        @block.children << s(:int, 1)

        assert_equal [[s(:int, 1)]], @block.data
      end

      test "#data without data nodes returns an empty array" do
        @block.children << s(:send, nil, :a)

        assert_equal [], @block.data
      end

      test "#data with multiple rows returns multiple rows" do
        @block.children << s(:send, nil, :a)
        @block.children << s(:int, 1)
        @block.children << s(:int, 2)

        expected = [
          [s(:int, 1)],
          [s(:int, 2)]
        ]

        assert_equal expected, @block.data
      end

      test "#data pipes returns a flattened array of nodes" do
        @block.children << s(:send, nil, :a)
        @block.children << s(:send, s(:int, 1), :|, s(:int, 2))
        @block.children << s(:send, s(:send, s(:int, 1), :|, s(:int, 2)), :|, s(:send, nil, :method_call))

        expected = [
          [s(:int, 1), s(:int, 2)],
          [s(:int, 1), s(:int, 2), s(:send, nil, :method_call)],
        ]

        assert_equal expected, @block.data
      end

      test "#data pipes works when subtracting from nodes" do
        @block.children << s(:send, s(:send, nil, :a), :|, s(:send, nil, :b))
        @block.children << s(:send, s(:send, s(:int, 2), :-, s(:int, 1)), :|, s(:int, 2))

        expected = [
          [ s(:send, s(:int, 2), :-, s(:int, 1)), s(:int, 2)],
        ]

        assert_equal expected, @block.data
      end
    end
  end
end
