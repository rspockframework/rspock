# frozen_string_literal: true
require 'rspock/ast/node'

module RSpock
  module AST
    module Parser
      # Classifies raw Ruby AST statements into RSpock node types for Then/Expect blocks.
      #
      # - Assignments pass through as raw AST (no wrapping).
      # - Binary operators (==, !=, =~, etc.) become :rspock_binary_statement nodes.
      # - Everything else becomes :rspock_statement nodes with the original source text captured.
      class StatementParser
        include RSpock::AST::NodeBuilder

        BINARY_OPERATORS = %i[== != =~ !~ > < >= <=].freeze
        ASSIGNMENT_TYPES = %i[lvasgn masgn op_asgn or_asgn and_asgn].freeze

        def parse(node)
          return node if assignment?(node)
          return build_binary_statement(node) if binary_statement?(node)

          build_statement(node)
        end

        private

        def assignment?(node)
          ASSIGNMENT_TYPES.include?(node.type)
        end

        def binary_statement?(node)
          node.type == :send &&
            node.children.length == 3 &&
            BINARY_OPERATORS.include?(node.children[1])
        end

        def build_binary_statement(node)
          s(:rspock_binary_statement, node.children[0], s(:sym, node.children[1]), node.children[2])
        end

        def build_statement(node)
          source = node.loc&.expression&.source || node.inspect
          s(:rspock_statement, node, s(:str, source))
        end
      end
    end
  end
end
