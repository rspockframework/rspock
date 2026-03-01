# frozen_string_literal: true
require 'rspock/ast/parser/block'
require 'rspock/ast/parser/statement_parser'

module RSpock
  module AST
    module Parser
      class ExpectBlock < Block
        def initialize(node)
          super(:Expect, node)
        end

        def can_start?
          true
        end

        def can_end?
          true
        end

        def successors
          @successors ||= [:Cleanup, :Where].freeze
        end

        def to_rspock_node
          statement_parser = StatementParser.new
          spock_children = @children.map { |child| statement_parser.parse(child) }

          if spock_children.any? { |c| c.type == :rspock_raises }
            raise BlockError, "raises() is not supported in Expect blocks @ #{range}. Use a When + Then block instead."
          end

          s(:rspock_expect, *spock_children)
        end
      end
    end
  end
end
