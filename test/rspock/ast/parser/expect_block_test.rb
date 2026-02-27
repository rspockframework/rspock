# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/expect_block'

module RSpock
  module AST
    module Parser
      class ExpectBlockTest < Minitest::Test
        extend RSpock::Declarative
        include ASTTransform::TransformationHelper

        def setup
          @block = RSpock::AST::Parser::ExpectBlock.new(nil)
        end

        test "#can_start? returns true" do
          assert_equal true, @block.can_start?
        end

        test "#can_end? returns true" do
          assert_equal true, @block.can_end?
        end

        test "#successors returns the correct successors" do
          assert_equal [:Cleanup, :Where], @block.successors
        end

        test "#successors is frozen" do
          assert_equal true, @block.successors.frozen?
        end

        test "#type is :Expect" do
          assert_equal :Expect, @block.type
        end

        test "#children returns raw children without transformation" do
          comparison = s(:send, 1, :==, 2)
          @block << comparison

          actual = @block.children
          assert_equal [comparison], actual
        end

        test "#to_rspock_node returns :rspock_expect node with children" do
          @block << s(:send, 1, :==, 2)
          @block << s(:send, 1, :!=, 2)

          ir = @block.to_rspock_node
          assert_equal :rspock_expect, ir.type
          assert_equal 2, ir.children.length
        end
      end
    end
  end
end
