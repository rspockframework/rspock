# frozen_string_literal: true
require 'rspock/ast/node'

module RSpock
  module AST
    module Parser
      class BlockError < StandardError; end

      class Block
        include RSpock::AST::NodeBuilder

        # Constructs a new Block.
        #
        # @param type [Symbol] The Block type.
        # @param node [Parser::AST::Node] The node associated to this Block.
        def initialize(type, node)
          @type = type
          @node = node
          @children = []
        end

        attr_reader :type, :node

        # Adds the given +child_node+ to this Block.
        #
        # @param child_node [Parser::AST::Node] The node to be added.
        def <<(child_node)
          @children << child_node
        end

        # Retrieves the Parser::Source::Range for this Block.
        #
        # @return [Parser::Source::Range] The range.
        def range
          node&.loc&.expression || "?"
        end

        # Whether this block can be the first block in a test method.
        def can_start?
          false
        end

        # Whether this block can be the last block in a test method.
        def can_end?
          false
        end

        # Retrieves the valid successors for this Block.
        #
        # @return [Array<Symbol>] This Block's successors.
        def successors
          @successors ||= [].freeze
        end

        # Retrieves the duped array of children AST nodes for this Block.
        #
        # @return [Array<Parser::AST::Node>] The children nodes.
        def children
          @children.dup
        end

        # Converts this Block into an RSpock node.
        #
        # @return [Parser::AST::Node] A node with type :rspock_<block_type>.
        def to_rspock_node
          rspock_type = :"rspock_#{type.downcase}"
          s(rspock_type, *@children)
        end

        # Checks whether or not the given +block+ is a valid successor for this Block.
        #
        # @param block [Block] The candidate successor.
        #
        # @return [Boolean] True if the given block is a valid successor, false otherwise.
        def valid_successor?(block)
          successors.include?(block.type)
        end

        # Retrieves the error message for succession errors.
        #
        # @return [String] The error message.
        def succession_error_msg
          "Block #{type} @ #{range} must be followed by one of these Blocks: #{successors}"
        end
      end
    end
  end
end
