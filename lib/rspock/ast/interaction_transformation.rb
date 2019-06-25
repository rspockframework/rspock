# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    class InteractionTransformation < ASTTransform::AbstractTransformation
      class InteractionError < RuntimeError; end

      def run(node)
        return node unless interaction_node?(node)

        parse_node(node)
        transform_node
      end

      def interaction_node?(node)
        return false if node.nil?

        node.type == :send && node.children[1] == :*
      end

      private

      ALLOWED_NODES = [:send, :lvar, :int]
      private_constant(:ALLOWED_NODES)

      def transform_node
        result = chain_call(@receiver_node, :expects, s(:sym, @message))
        result = chain_call(result, :with, *@arg_nodes) unless @arg_nodes.empty?

        if any_matcher_node?(@times_node)
          result = chain_call(result, :at_least, s(:int, 0))
        elsif ALLOWED_NODES.include?(@times_node.type)
          result = chain_call(result, :times, @times_node)
        elsif @times_node.type == :begin && @times_node.children[0]&.type == :irange
          min_node, max_node = @times_node.children[0].children

          result = transform_irange_node(result, min_node, max_node)
        elsif @times_node.type == :begin && @times_node.children[0]&.type == :erange
          min_node, max_node = @times_node.children[0].children
          max_node = chain_call(max_node, :-, s(:int, 1))

          result = transform_erange_node(result, min_node, max_node)
        else
          raise ArgumentError, "Unrecognized times constraint in interaction: #{@times_node&.loc&.expression || "?"}"
        end

        result
      end

      def chain_call(receiver_node, method_name, *arg_nodes)
        s(:send, receiver_node, method_name, *arg_nodes)
      end

      def transform_irange_node(receiver_node, min_node, max_node)
        result = receiver_node

        if any_matcher_node?(min_node) && any_matcher_node?(max_node)
          result = chain_call(result, :at_least, s(:int, 0))
        elsif !any_matcher_node?(min_node) && any_matcher_node?(max_node)
          result = chain_call(result, :at_least, min_node)
        elsif any_matcher_node?(min_node) && !any_matcher_node?(max_node)
          result = chain_call(result, :at_least, s(:int, 0))
          result = chain_call(result, :at_most, max_node)
        elsif !any_matcher_node?(min_node) && !any_matcher_node?(max_node)
          result = chain_call(result, :at_least, min_node)
          result = chain_call(result, :at_most, max_node)
        end

        result
      end

      def transform_erange_node(receiver_node, min_node, max_node)
        result = receiver_node

        if any_matcher_node?(min_node) && any_matcher_node?(max_node.children[0])
          result = chain_call(result, :at_least, s(:int, 0))
        elsif !any_matcher_node?(min_node) && any_matcher_node?(max_node.children[0])
          result = chain_call(result, :at_least, min_node)
        elsif any_matcher_node?(min_node) && !any_matcher_node?(max_node.children[0])
          result = chain_call(result, :at_least, s(:int, 0))
          result = chain_call(result, :at_most, max_node)
        elsif !any_matcher_node?(min_node) && !any_matcher_node?(max_node.children[0])
          result = chain_call(result, :at_least, min_node)
          result = chain_call(result, :at_most, max_node)
        end

        result
      end

      def any_matcher_node?(node)
        node.type == :send && node.children[0].nil? && node.children[1] == :_
      end

      def parse_node(node)
        parse_lhs(node.children[0])
        parse_rhs(node.children[2])
      end

      def parse_lhs(node)
        @times_node = node

        case @times_node.type
        when *ALLOWED_NODES
          # OK
        when :begin
          if node.children.count > 1
            raise_lhs_error(node, msg_prefix: "Left-hand side of ", msg_suffix: " or a range in parentheses")
          end
          case node.children[0].type
          when :irange, :erange
            unless ALLOWED_NODES.include?(node.children[0].children[0].type)
              raise_lhs_error(node.children[0].children[0], msg_prefix: "Minimum range of ")
            end
            unless ALLOWED_NODES.include?(node.children[0].children[1].type)
              raise_lhs_error(node.children[0].children[1], msg_prefix: "Maximum range of ")
            end
          else
            raise_lhs_error(node, msg_prefix: "Left-hand side of ", msg_suffix: " or a range in parentheses")
          end
        else
          raise_lhs_error(node, msg_prefix: "Left-hand side of ", msg_suffix: " or a range in parentheses")
        end
      end

      def parse_rhs(node)
        if node.type != :send
          raise InteractionError, "Right-hand side of Interaction @ #{range(node)} must be a :send node."
        end

        @receiver_node, @message, *@arg_nodes = node.children

        if @receiver_node.nil?
          raise InteractionError, "Right-hand side of Interaction @ #{range(node)} must have a receiver."
        end
      end

      def range(node)
        node&.loc&.expression || "?"
      end

      def raise_lhs_error(node, msg_prefix: "", msg_suffix: "")
        raise InteractionError, "#{msg_prefix}Interaction @ #{range(node)} must be one of "\
          "#{ALLOWED_NODES}#{msg_suffix}."
      end
    end
  end
end
