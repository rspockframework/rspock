# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/end_block'

module RSpock
  module AST
    class EndBlockTest < Minitest::Test
      extend RSpock::Declarative

      def setup
        @block = RSpock::AST::EndBlock.new
      end

      test "#node_container? returns false by default" do
        assert_equal false, @block.node_container?
      end

      test "#successors returns empty array" do
        assert_equal [], @block.successors
      end

      test "#successors is frozen" do
        assert_equal true, @block.successors.frozen?
      end

      test "#type is :End" do
        assert_equal :End, @block.type
      end
    end
  end
end
