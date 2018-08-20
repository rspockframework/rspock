# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/cleanup_block'

module RSpock
  module AST
    class CleanupBlockTest < Minitest::Test
      extend RSpock::Declarative

      def setup
        @block = RSpock::AST::CleanupBlock.new(nil)
      end

      test "#successors returns the correct successors" do
        assert_equal [:Where, :End], @block.successors
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
