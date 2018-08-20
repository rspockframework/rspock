# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/block'

module RSpock
  module AST
    class BlockTest < Minitest::Test
      extend RSpock::Declarative

      test "#successors returns the correct successors" do
        block = RSpock::AST::Block.new(:Start, nil)

        assert_equal [:End], block.successors
      end

      test "#successors is frozen" do
        block = RSpock::AST::Block.new(:Start, nil)

        assert_equal true, block.successors.frozen?
      end

      test "#to_children_ast is duped" do
        block = RSpock::AST::Block.new(:Start, nil)

        refute_same block.children, block.to_children_ast
      end
    end
  end
end
