# frozen_string_literal: true
module RSpock
  module AST
    class BlockError < StandardError; end

    class Block
      # Constructs a new Block.
      #
      # @param type [Symbol] The Block type.
      # @param node [Parser::AST::Node] The node associated to this Block.
      def initialize(type, node)
        @type = type
        @node = node
        @children = []
        @node_container = true
      end

      attr_reader :type, :node

      # Adds the given +child_node+ to this Block.
      #
      # @param child_node [Parser::AST::Node] The node to be added.
      #
      # @raise [BlockError] if this Block cannot contain other nodes.
      def <<(child_node)
        raise BlockError, succession_error_msg unless node_container?

        @children << child_node
      end

      # Adds the given +child_node+ to the beginning of this Block.
      #
      # @param child_node [Parser::AST::Node] The node to be added.
      #
      # @raise [BlockError] if this Block cannot contain other nodes.
      def unshift(child_node)
        raise BlockError, succession_error_msg unless node_container?

        @children.unshift(child_node)
      end

      # Checks whether this Block can contain other nodes.
      #
      # @return [Boolean] True if this Block can contain other nodes, false otherwise.
      def node_container?
        @node_container
      end

      # Sets whether this Block can contain other nodes.
      #
      # @param value [Boolean] True if this Block can contain other nodes, false otherwise.
      def node_container=(value)
        @node_container = value
      end

      # Retrieves the Parser::Source::Range for this Block.
      #
      # @return [Parser::Source::Range] The range.
      def range
        node&.loc&.expression || "?"
      end

      # Retrieves the valid successors for this Block.
      # Note: Defaults to [:End].
      #
      # @return [Array<Symbol>] This Block's successors.
      def successors
        @successors ||= [:End].freeze
      end

      # Retrieves the duped array of children AST nodes for this Block.
      #
      # @return [Array<Parser::AST::Node>] The children nodes.
      def children
        @children.dup
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
