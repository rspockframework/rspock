# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/block'

module RSpock
  module AST
    class BlockTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      def setup
        @block = RSpock::AST::Block.new(:Start, nil)
        @node = s(:send, nil, :a)
      end

      test "#<< adds the given node if node_container is true" do
        @block << @node

        assert_equal [@node], @block.children
      end

      test "#<< raises if node_container is false" do
        @block.node_container = false

        assert_raises RSpock::AST::BlockError do
          @block << @node
        end
      end

      test "#unshift adds the given node to the beginning of the Block node_container is true" do
        @block << 1

        @block.unshift(@node)

        assert_equal [@node, 1], @block.children
      end

      test "#unshift raises if node_container is false" do
        @block.node_container = false

        assert_raises RSpock::AST::BlockError do
          @block.unshift(@node)
        end
      end

      test "#range returns '?' if node does not contain range information" do
        assert_equal '?', @block.range
      end

      test "#successors returns the correct successors" do
        assert_equal [:End], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#children is duped" do
        original = @block.children

        modified = @block.children
        modified << @node

        refute_same original, modified
        refute_equal original, modified
      end

      test "#valid_successor? returns true if block passed is a valid successor" do
        end_block = RSpock::AST::Block.new(:End, nil)

        assert_equal true, @block.valid_successor?(end_block)
      end

      test "#valid_successor? returns false if block passed is not a valid successor" do
        end_block = RSpock::AST::Block.new(:DummyType, nil)

        assert_equal false, @block.valid_successor?(end_block)
      end

      test "#succession_error_msg returns the correct error message" do
        expected = "Block Start @ ? must be followed by one of these Blocks: [:End]"

        assert_equal expected, @block.succession_error_msg
      end
    end
  end
end
