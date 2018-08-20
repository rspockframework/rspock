# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/start_block'

module RSpock
  module AST
    class StartBlockTest < Minitest::Test
      extend RSpock::Declarative

      def setup
        @block = RSpock::AST::StartBlock.new
      end

      test "#successors returns the correct successors" do
        assert_equal [:Given, :When, :Then], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#type is :End" do
        assert_equal :Start, @block.type
      end
    end
  end
end
