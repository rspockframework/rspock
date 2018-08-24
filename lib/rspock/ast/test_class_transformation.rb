# frozen_string_literal: true
require 'rspock/ast/abstract_transformation'
require 'rspock/ast/start_block'
require 'rspock/ast/given_block'
require 'rspock/ast/when_block'
require 'rspock/ast/then_block'
require 'rspock/ast/expect_block'
require 'rspock/ast/cleanup_block'
require 'rspock/ast/where_block'
require 'rspock/ast/end_block'
require 'rspock/ast/test_method_transformation'

module RSpock
  module AST
    class TestClassTransformation < AbstractTransformation
      class BlockASTError < RuntimeError; end

      DefaultSourceMap = {
        Given: RSpock::AST::GivenBlock,
        When: RSpock::AST::WhenBlock,
        Then: RSpock::AST::ThenBlock,
        Expect: RSpock::AST::ExpectBlock,
        Cleanup: RSpock::AST::CleanupBlock,
        Where: RSpock::AST::WhereBlock,
      }

      def initialize(start_block_class: StartBlock, end_block_class: EndBlock, source_map: DefaultSourceMap)
        super()
        @start_block_class = start_block_class
        @source_map = source_map
        @end_block_class = end_block_class
      end

      INCLUDE_RSPOCK_AST = s(:send,
                             nil,
                             :include,
                             s(:const,
                               nil,
                               :RSpock))
      BREAK_AST = s(:break)

      def on_class(node)
        if node.children[2]&.type == :begin
          children = node.children.dup
          children[2] = process_rspock(children[2])

          node.updated(nil, children)
        else
          process_rspock(node)
        end
      end

      def on_casgn(node)
        if node.children[2]&.type == :block
          children = node.children.dup
          children[2] = process_casgn_block(children[2])

          node.updated(nil, children)
        else
          super
        end
      end

      def process_casgn_block(node)
        if node.children[2]&.type == :begin
          children = node.children.dup
          children[2] = process_rspock(children[2])

          # Optimization to remove empty :begin node
          children.slice!(2) if children[2].children.empty?

          node.updated(nil, children)
        else
          process_rspock(node)
        end
      end

      def process_rspock(node)
        index = node&.children&.find_index{ |child| child == INCLUDE_RSPOCK_AST }
        if index
          index = node.children.find_index(INCLUDE_RSPOCK_AST)
          indexes_to_reject = [index]

          if node.children[index + 1] == BREAK_AST
            indexes_to_reject << index + 1
          end

          children = node.children.reject.each_with_index { |node, index| indexes_to_reject.include?(index) }
          node.updated(nil, children.map { |node| process(node) }.unshift(EXTEND_RSPOCK_DECLARATIVE))
        else
          node.updated(nil, process_all(node))
        end
      end

      def on_block(node)
        if node.children[0]&.children[1] != :test
          return node.updated(nil, process_all(node))
        end

        TestMethodTransformation.new(@source_map, @start_block_class, @end_block_class).run(node)
      end
    end
  end
end
