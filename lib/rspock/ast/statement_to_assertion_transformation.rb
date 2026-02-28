# frozen_string_literal: true
require 'rspock/ast/node'

module RSpock
  module AST
    # Transforms :rspock_binary_statement and :rspock_statement nodes into Minitest assertion calls.
    #
    # Binary statements dispatch to specialized assertions (assert_equal, assert_match, assert_operator).
    # General statements use assert_equal(true/false, expr, source_message) with negation detection.
    class StatementToAssertionTransformation
      include RSpock::AST::NodeBuilder

      BINARY_DISPATCH = {
        :==  => :assert_equal,
        :!=  => :refute_equal,
        :=~  => :assert_match,
        :'!~' => :refute_match,
      }.freeze

      OPERATOR_ASSERTIONS = %i[> < >= <=].freeze

      def run(node)
        case node.type
        when :rspock_binary_statement
          transform_binary_statement(node)
        when :rspock_statement
          transform_statement(node)
        else
          node
        end
      end

      private

      def transform_binary_statement(node)
        lhs = node.lhs
        op = node.operator.children[0]
        rhs = node.rhs

        if (assertion = BINARY_DISPATCH[op])
          s(:send, nil, assertion, rhs, lhs)
        elsif OPERATOR_ASSERTIONS.include?(op)
          s(:send, nil, :assert_operator, lhs, s(:sym, op), rhs)
        else
          s(:send, nil, :assert_operator, lhs, s(:sym, op), rhs)
        end
      end

      def transform_statement(node)
        expr = node.expression
        source_text = node.source.children[0]

        if negated?(expr)
          inner = expr.children[0]
          message = "Expected \"#{source_text}\" to be false"
          s(:send, nil, :assert_equal, s(:false), inner, s(:str, message))
        else
          message = "Expected \"#{source_text}\" to be true"
          s(:send, nil, :assert_equal, s(:true), expr, s(:str, message))
        end
      end

      def negated?(node)
        node.type == :send && node.children[1] == :! && node.children.length == 2
      end
    end
  end
end
