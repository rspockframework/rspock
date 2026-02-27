# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/parser/block'

module RSpock
  module AST
    module Parser
      class BlockTest < Minitest::Test
        extend RSpock::Declarative
        include RSpock::Helpers::TransformationHelper

        def setup
          @block = RSpock::AST::Parser::Block.new(:Start, nil)
          @node = s(:send, nil, :a)
        end

      test "#<< adds the given node" do
        @block << @node

        assert_equal [@node], @block.children
      end

      test "#range returns '?' if node does not contain range information" do
        assert_equal '?', @block.range
      end

      test "#successors returns empty array by default" do
        assert_equal [], @block.successors
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
        block = RSpock::AST::Parser::Block.new(:Start, nil)
        def block.successors
          [:Next]
        end

        next_block = RSpock::AST::Parser::Block.new(:Next, nil)

        assert_equal true, block.valid_successor?(next_block)
      end

      test "#valid_successor? returns false if block passed is not a valid successor" do
        dummy_block = RSpock::AST::Parser::Block.new(:DummyType, nil)

        assert_equal false, @block.valid_successor?(dummy_block)
      end

      test "#succession_error_msg returns the correct error message" do
        expected = "Block Start @ ? must be followed by one of these Blocks: []"

        assert_equal expected, @block.succession_error_msg
      end

      test "#can_start? returns false by default" do
        assert_equal false, @block.can_start?
      end

      test "#can_end? returns false by default" do
        assert_equal false, @block.can_end?
      end
      end
    end
  end
end
