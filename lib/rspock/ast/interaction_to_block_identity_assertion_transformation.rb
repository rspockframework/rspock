# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/node'

module RSpock
  module AST
    # Transforms an :rspock_interaction node into an assert_same assertion
    # when a block_pass (&var) is present.
    #
    # Returns the node unchanged (passthrough) when no block_pass is present.
    class InteractionToBlockIdentityAssertionTransformation < ASTTransform::AbstractTransformation
      def initialize(index = 0)
        @index = index
      end

      def run(interaction)
        return interaction unless interaction.type == :rspock_interaction
        return interaction unless interaction.block_pass

        capture_var = :"__rspock_blk_#{@index}"
        block_var = interaction.block_pass.children[0]

        s(:send, nil, :assert_same,
          block_var,
          s(:send, s(:lvar, capture_var), :call)
        )
      end
    end
  end
end
