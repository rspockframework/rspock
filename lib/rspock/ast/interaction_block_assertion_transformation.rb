# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    # Transforms an interaction block into an assertion that checks if the block
    # is the same as the captured block passed to the interaction.
    # 
    # @example
    #   1 * receiver.message(&my_proc)
    #   => assert_same(my_proc, __rspock_blk_0.call)
    #
    # @see InteractionTransformation
    class InteractionBlockAssertionTransformation < ASTTransform::AbstractTransformation
      # @param index [Integer] the index of the block capture variable
      def initialize(index = 0)
        @index = index
      end

      def run(node)
        block_pass = extract_block_pass(node)
        return nil unless block_pass

        capture_var = :"__rspock_blk_#{@index}"
        block_var = block_pass.children[0]

        s(:send, nil, :assert_same,
          block_var,
          s(:send, s(:lvar, capture_var), :call)
        )
      end

      private

      def extract_block_pass(node)
        # Unwrap >> return value
        if node.type == :send && node.children[1] == :>>
          node = node.children[0]
        end

        return nil unless node.type == :send && node.children[1] == :*

        rhs = node.children[2]
        return nil unless rhs.type == :send

        rhs.children[2..].find { |n| n.type == :block_pass }
      end
    end
  end
end
