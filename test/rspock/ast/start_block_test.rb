# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'rspock/ast/start_block'

module RSpock
  module AST
    class StartBlockTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      def setup
        @block = RSpock::AST::StartBlock.new(nil)
      end

      test "#node_container? returns false by default" do
        assert_equal false, @block.node_container?
      end

      test "#successors returns the correct successors when children are empty" do
        assert_equal false, @block.node_container?

        assert_equal [:Given, :When, :Expect], @block.successors
      end

      test "#successors returns the correct successors when block contains children" do
        @block.node_container = true
        @block << s(:send, nil, :a)

        assert_equal [:End], @block.successors
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
