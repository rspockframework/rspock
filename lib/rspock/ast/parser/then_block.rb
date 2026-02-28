# frozen_string_literal: true
require 'rspock/ast/parser/block'
require 'rspock/ast/parser/interaction_parser'
require 'rspock/ast/parser/statement_parser'

module RSpock
  module AST
    module Parser
      class ThenBlock < Block
        def initialize(node)
          super(:Then, node)
        end

        def can_end?
          true
        end

        def successors
          @successors ||= [:Cleanup, :Where].freeze
        end

        def to_rspock_node
          interaction_parser = InteractionParser.new
          statement_parser = StatementParser.new

          spock_children = @children.map do |child|
            parsed = interaction_parser.parse(child)
            next parsed unless parsed.equal?(child)

            statement_parser.parse(child)
          end

          s(:rspock_then, *spock_children)
        end
      end
    end
  end
end
