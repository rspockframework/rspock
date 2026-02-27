# frozen_string_literal: true
require 'rspock/ast/node'

module RSpock
  module AST
    module Parser
      # Parses a Ruby test method AST node into a self-contained RSpock AST.
      #
      # Input:  s(:block, s(:send, nil, :test, ...), s(:args), s(:begin, ...))
      # Output: s(:rspock_test,
      #           s(:rspock_def, method_call_node, args_node),
      #           s(:rspock_body, s(:rspock_given, ...), s(:rspock_when, ...), ...),
      #           s(:rspock_where, ...))   # optional
      class TestMethodParser
        include RSpock::AST::NodeBuilder

        def initialize(block_registry, strict: true)
          @block_registry = block_registry
          @strict = strict
        end

        # Parses a Ruby test method AST into an RSpock AST (TestNode).
        # Returns nil when non-strict and no RSpock blocks are found.
        def parse(node)
          blocks = parse_blocks(node)

          if blocks.empty?
            return nil unless @strict
            raise BlockError, "Test method @ #{node.loc&.expression || '?'} must start with one of: Given, When, Expect"
          end

          validate_blocks(blocks, node)
          build_rspock_ast(node, blocks)
        end

        private

        def parse_blocks(node)
          blocks = []
          test_method_nodes(node).each do |n|
            new_block = parse_block(n)
            if new_block
              validate_succession(blocks, new_block)
              blocks << new_block
            elsif blocks.empty?
              raise BlockError, "Test method must start with one of: Given, When, Expect" if @strict
              # non-strict: ignore pre-block statements in plain minitest tests
            else
              # regular statement — associate with the current block as a child
              blocks.last << n
            end
          end
          blocks
        end

        def parse_block(node)
          return unless @block_registry.key?(node.children[1])

          @block_registry[node.children[1]].new(node)
        end

        def validate_succession(blocks, new_block)
          return if blocks.empty?

          current = blocks.last
          unless current.valid_successor?(new_block)
            raise BlockError, current.succession_error_msg
          end
        end

        def validate_blocks(blocks, node)
          unless blocks.first.can_start?
            raise BlockError, "Test method @ #{node.loc&.expression || '?'} must start with one of: Given, When, Expect"
          end

          unless blocks.last.can_end?
            raise BlockError, "Block #{blocks.last.type} @ #{blocks.last.range} must be followed by one of these Blocks: #{blocks.last.successors}"
          end
        end

        def test_method_nodes(node)
          return [] if node.children[2].nil?

          node.children[2]&.type == :begin ? node.children[2].children : [node.children[2]]
        end

        def build_rspock_ast(node, blocks)
          def_node = s(:rspock_def, node.children[0], node.children[1])
          where_block = blocks.find { |b| b.type == :Where }
          body_blocks = blocks.reject { |b| b.type == :Where }

          body_node = s(:rspock_body, *body_blocks.map(&:to_rspock_node))

          if where_block
            s(:rspock_test, def_node, body_node, where_block.to_rspock_node)
          else
            s(:rspock_test, def_node, body_node)
          end
        end
      end
    end
  end
end
