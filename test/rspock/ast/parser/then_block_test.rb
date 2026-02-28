# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/then_block'

module RSpock
  module AST
    module Parser
      class ThenBlockTest < Minitest::Test
        extend RSpock::Declarative
        include ASTTransform::TransformationHelper

        INTERACTION_NODE = s(:send, s(:int, 1), :*, s(:send, :receiver, :message))

        def setup
          @block = RSpock::AST::Parser::ThenBlock.new(nil)
          @transformer = ASTTransform::Transformer.new
        end

        test "#can_start? returns false" do
          assert_equal false, @block.can_start?
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

        test "#type is :Then" do
          assert_equal :Then, @block.type
        end

        test "#children returns raw children without transformation" do
          comparison = s(:send, 1, :==, 2)
          @block << comparison
          @block << INTERACTION_NODE

          assert_equal [comparison, INTERACTION_NODE], @block.children
        end

        test "#to_rspock_node returns :rspock_then node" do
          @block << s(:send, 1, :==, 2)

          ir = @block.to_rspock_node
          assert_equal :rspock_then, ir.type
          assert_equal 1, ir.children.length
          assert_equal :rspock_binary_statement, ir.children[0].type
        end

        test "#to_rspock_node converts interaction nodes to :rspock_interaction" do
          node = @transformer.build_ast('1 * receiver.message')
          @block << node

          ir = @block.to_rspock_node
          assert_equal :rspock_then, ir.type
          assert_equal 1, ir.children.length
          assert_equal :rspock_interaction, ir.children[0].type
        end

        test "#to_rspock_node wraps comparison children as binary statements" do
          @block << s(:send, 1, :==, 2)

          ir = @block.to_rspock_node
          child = ir.children[0]
          assert_equal :rspock_binary_statement, child.type
          assert_equal 1, child.lhs
          assert_equal s(:sym, :==), child.operator
          assert_equal 2, child.rhs
        end

        test "#to_rspock_node parses interaction with correct structure" do
          node = @transformer.build_ast('1 * receiver.message("arg")')
          @block << node

          ir = @block.to_rspock_node
          interaction = ir.children[0]

          assert_equal :rspock_interaction, interaction.type

          cardinality = interaction.children[0]
          assert_equal s(:int, 1), cardinality

          receiver = interaction.children[1]
          assert_equal :send, receiver.type

          message = interaction.children[2]
          assert_equal s(:sym, :message), message

          args = interaction.children[3]
          assert_equal :array, args.type
          assert_equal 1, args.children.length
        end

        test "#to_rspock_node parses interaction with &block" do
          node = @transformer.build_ast('1 * receiver.message(&my_proc)')
          @block << node

          ir = @block.to_rspock_node
          interaction = ir.children[0]

          assert_equal :rspock_interaction, interaction.type

          block_pass = interaction.children[5]
          refute_nil block_pass
          assert_equal :block_pass, block_pass.type
        end

        test "#to_rspock_node parses interaction with >> outcome" do
          node = @transformer.build_ast('1 * receiver.message >> "result"')
          @block << node

          ir = @block.to_rspock_node
          interaction = ir.children[0]

          assert_equal :rspock_interaction, interaction.type

          outcome = interaction.outcome
          refute_nil outcome
          assert_equal :rspock_returns, outcome.type
        end

        test "#to_rspock_node handles mixed interaction and comparison nodes" do
          @block << s(:send, 1, :==, 2)
          node = @transformer.build_ast('1 * receiver.message(&my_proc)')
          @block << node

          ir = @block.to_rspock_node
          assert_equal 2, ir.children.length
          assert_equal :rspock_binary_statement, ir.children[0].type
          assert_equal :rspock_interaction, ir.children[1].type
        end

        test "#to_rspock_node with multiple interactions has correct indices" do
          node0 = @transformer.build_ast('1 * receiver.method1(&proc1)')
          node1 = @transformer.build_ast('1 * receiver.method2(&proc2)')
          @block << node0
          @block << node1

          ir = @block.to_rspock_node
          assert_equal 2, ir.children.length
          assert_equal :rspock_interaction, ir.children[0].type
          assert_equal :rspock_interaction, ir.children[1].type

          assert_equal s(:sym, :method1), ir.children[0].children[2]
          assert_equal s(:sym, :method2), ir.children[1].children[2]
        end
      end
    end
  end
end
