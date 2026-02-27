# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/given_block'

module RSpock
  module AST
    module Parser
      class GivenBlockTest < Minitest::Test
        extend RSpock::Declarative

        def setup
          @block = RSpock::AST::Parser::GivenBlock.new(nil)
        end

        test "#can_start? returns true" do
          assert_equal true, @block.can_start?
        end

        test "#can_end? returns false" do
          assert_equal false, @block.can_end?
        end

        test "#successors returns the correct successors" do
          assert_equal [:When, :Expect], @block.successors
        end

        test "#successors is frozen" do
          assert_equal true, @block.successors.frozen?
        end

        test "#type is :Given" do
          assert_equal :Given, @block.type
        end
      end
    end
  end
end
