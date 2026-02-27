# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/cleanup_block'

module RSpock
  module AST
    module Parser
      class CleanupBlockTest < Minitest::Test
        extend RSpock::Declarative

        def setup
          @block = RSpock::AST::Parser::CleanupBlock.new(nil)
        end

        test "#can_start? returns false" do
          assert_equal false, @block.can_start?
        end

        test "#can_end? returns true" do
          assert_equal true, @block.can_end?
        end

        test "#successors returns the correct successors" do
          assert_equal [:Where], @block.successors
        end

        test "#successors is frozen" do
          assert_equal true, @block.successors.frozen?
        end

        test "#type is :Cleanup" do
          assert_equal :Cleanup, @block.type
        end
      end
    end
  end
end
