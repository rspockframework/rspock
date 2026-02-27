# frozen_string_literal: true
require 'rspock/ast/parser/block'
require 'rspock/ast/parser/interaction_parser'

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
          parser = InteractionParser.new
          spock_children = @children.map { |child| parser.parse(child) }
          s(:rspock_then, *spock_children)
        end
      end
    end
  end
end
