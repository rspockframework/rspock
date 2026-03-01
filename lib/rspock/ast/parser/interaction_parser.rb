# frozen_string_literal: true
require 'rspock/ast/node'

module RSpock
  module AST
    module Parser
      # Parses raw Ruby AST interaction nodes into structured :rspock_interaction nodes.
      #
      # Input:  1 * receiver.message("arg", &blk) >> "result"
      # Output: s(:rspock_interaction, cardinality, receiver, sym, args, outcome, block_pass)
      #
      # :rspock_interaction children:
      #   [0] cardinality  - e.g. s(:int, 1), s(:begin, s(:irange, ...)), s(:send, nil, :_)
      #   [1] receiver     - e.g. s(:send, nil, :subscriber)
      #   [2] message      - e.g. s(:sym, :receive)
      #   [3] args         - nil if no args, s(:array, *arg_nodes) otherwise
      #   [4] outcome      - nil if no >>, otherwise s(:rspock_stub_returns, value) or s(:rspock_stub_raises, *args)
      #   [5] block_pass   - nil if no &, otherwise s(:block_pass, ...)
      class InteractionParser
        include RSpock::AST::NodeBuilder

        class InteractionError < RuntimeError; end

        ALLOWED_CARDINALITY_NODES = [:send, :lvar, :int].freeze

        def interaction_node?(node)
          return false if node.nil?
          return true if node.type == :send && node.children[1] == :*
          return true if return_value_node?(node)

          false
        end

        def parse(node)
          return node unless interaction_node?(node)

          if return_value_node?(node)
            outcome = parse_outcome(node.children[2])
            node = node.children[0]
          end

          cardinality = node.children[0]
          validate_cardinality(cardinality)

          rhs = node.children[2]
          receiver, message, args, block_pass = parse_rhs(rhs)

          s(:rspock_interaction,
            cardinality,
            receiver,
            s(:sym, message),
            args,
            outcome,
            block_pass
          )
        end

        private

        def return_value_node?(node)
          node.type == :send && node.children[1] == :>> && interaction_node?(node.children[0])
        end

        def parse_outcome(node)
          if node.type == :send && node.children[0].nil? && node.children[1] == :raises
            s(:rspock_stub_raises, *node.children[2..])
          else
            s(:rspock_stub_returns, node)
          end
        end

        def validate_cardinality(node)
          case node.type
          when *ALLOWED_CARDINALITY_NODES
            # OK
          when :begin
            if node.children.count > 1
              raise_cardinality_error(node,
                msg_prefix: "Left-hand side of ",
                msg_suffix: " or a range in parentheses")
            end
            case node.children[0].type
            when :irange, :erange
              unless ALLOWED_CARDINALITY_NODES.include?(node.children[0].children[0].type)
                raise_cardinality_error(node.children[0].children[0], msg_prefix: "Minimum range of ")
              end
              unless ALLOWED_CARDINALITY_NODES.include?(node.children[0].children[1].type)
                raise_cardinality_error(node.children[0].children[1], msg_prefix: "Maximum range of ")
              end
            else
              raise_cardinality_error(node,
                msg_prefix: "Left-hand side of ",
                msg_suffix: " or a range in parentheses")
            end
          else
            raise_cardinality_error(node,
              msg_prefix: "Left-hand side of ",
              msg_suffix: " or a range in parentheses")
          end
        end

        def parse_rhs(node)
          if node.type == :block
            raise InteractionError, "Inline blocks (do...end / { }) are not supported in interactions @ #{range(node)}. " \
              "Use &var for block forwarding verification, or << for method body override (future)."
          end

          if node.type != :send
            raise InteractionError, "Right-hand side of Interaction @ #{range(node)} must be a :send node."
          end

          receiver, message, *arg_nodes = node.children

          if receiver.nil?
            raise InteractionError, "Right-hand side of Interaction @ #{range(node)} must have a receiver."
          end

          block_pass = arg_nodes.find { |n| n.type == :block_pass }
          if block_pass
            arg_nodes = arg_nodes.reject { |n| n.equal?(block_pass) }
          end

          args = arg_nodes.empty? ? nil : s(:array, *arg_nodes)

          [receiver, message, args, block_pass]
        end

        def range(node)
          node&.loc&.expression || "?"
        end

        def raise_cardinality_error(node, msg_prefix: "", msg_suffix: "")
          raise InteractionError, "#{msg_prefix}Interaction @ #{range(node)} must be one of " \
            "#{ALLOWED_CARDINALITY_NODES}#{msg_suffix}."
        end
      end
    end
  end
end
