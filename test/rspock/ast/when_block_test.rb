# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/when_block'

module RSpock
  module AST
    class WhenBlockTest < Minitest::Test
      extend RSpock::Declarative

      def setup
        @block = RSpock::AST::WhenBlock.new(nil)
      end

      test "#successors returns the correct successors" do
        assert_equal [:Then], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#type is :When" do
        assert_equal :When, @block.type
      end
    end
  end
end
