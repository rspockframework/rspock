# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/given_block'

module RSpock
  module AST
    class GivenBlockTest < Minitest::Test
      extend RSpock::Declarative

      def setup
        @block = RSpock::AST::GivenBlock.new(nil)
      end

      test "#successors returns the correct successors" do
        assert_equal [:When, :Cleanup, :Where, :End], @block.successors
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
