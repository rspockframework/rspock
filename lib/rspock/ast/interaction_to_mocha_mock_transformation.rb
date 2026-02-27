# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/node'

module RSpock
  module AST
    # Transforms an :rspock_interaction node into Mocha mock setup code.
    #
    # Input:  s(:rspock_interaction, cardinality, receiver, sym, args, outcome, block_pass)
    # Output: receiver.expects(:message).with(*args).times(n).returns(value)
    #
    # The outcome node type maps directly to the Mocha chain method:
    #   :rspock_returns -> .returns(value)
    #   :rspock_raises  -> .raises(exception_class, ...)
    #
    # When block_pass is present, wraps the expects chain with a BlockCapture.capture call.
    class InteractionToMochaMockTransformation < ASTTransform::AbstractTransformation
      OUTCOME_METHODS = {
        rspock_returns: :returns,
        rspock_raises: :raises,
      }.freeze

      def initialize(index = 0)
        @index = index
      end

      def run(interaction)
        return interaction unless interaction.type == :rspock_interaction

        result = chain_call(interaction.receiver, :expects, s(:sym, interaction.message))
        result = chain_call(result, :with, *interaction.args.children) if interaction.args
        result = build_cardinality(result, interaction.cardinality)
        result = chain_call(result, OUTCOME_METHODS.fetch(interaction.outcome.type), *interaction.outcome.children) if interaction.outcome

        if interaction.block_pass
          build_block_capture_setup(result, interaction.receiver, interaction.message)
        else
          result
        end
      end

      private

      def build_cardinality(result, cardinality)
        if any_matcher_node?(cardinality)
          chain_call(result, :at_least, s(:int, 0))
        elsif [:send, :lvar, :int].include?(cardinality.type)
          chain_call(result, :times, cardinality)
        elsif cardinality.type == :begin && cardinality.children[0]&.type == :irange
          min_node, max_node = cardinality.children[0].children
          build_irange(result, min_node, max_node)
        elsif cardinality.type == :begin && cardinality.children[0]&.type == :erange
          min_node, max_node = cardinality.children[0].children
          max_node = chain_call(max_node, :-, s(:int, 1))
          build_erange(result, min_node, max_node)
        else
          raise ArgumentError, "Unrecognized cardinality in :rspock_interaction: #{cardinality.type}"
        end
      end

      def build_irange(result, min_node, max_node)
        if any_matcher_node?(min_node) && any_matcher_node?(max_node)
          chain_call(result, :at_least, s(:int, 0))
        elsif !any_matcher_node?(min_node) && any_matcher_node?(max_node)
          chain_call(result, :at_least, min_node)
        elsif any_matcher_node?(min_node) && !any_matcher_node?(max_node)
          result = chain_call(result, :at_least, s(:int, 0))
          chain_call(result, :at_most, max_node)
        else
          result = chain_call(result, :at_least, min_node)
          chain_call(result, :at_most, max_node)
        end
      end

      def build_erange(result, min_node, max_node)
        if any_matcher_node?(min_node) && any_matcher_node?(max_node.children[0])
          chain_call(result, :at_least, s(:int, 0))
        elsif !any_matcher_node?(min_node) && any_matcher_node?(max_node.children[0])
          chain_call(result, :at_least, min_node)
        elsif any_matcher_node?(min_node) && !any_matcher_node?(max_node.children[0])
          result = chain_call(result, :at_least, s(:int, 0))
          chain_call(result, :at_most, max_node)
        else
          result = chain_call(result, :at_least, min_node)
          chain_call(result, :at_most, max_node)
        end
      end

      def build_block_capture_setup(expects_node, receiver, message)
        capture_var = :"__rspock_blk_#{@index}"

        capture_call = s(:lvasgn, capture_var,
          s(:send,
            s(:const, s(:const, s(:const, nil, :RSpock), :Helpers), :BlockCapture),
            :capture,
            receiver,
            s(:sym, message)
          )
        )

        s(:begin, expects_node, capture_call)
      end

      def chain_call(receiver_node, method_name, *arg_nodes)
        s(:send, receiver_node, method_name, *arg_nodes)
      end

      def any_matcher_node?(node)
        node.type == :send && node.children[0].nil? && node.children[1] == :_
      end
    end
  end
end
