# frozen_string_literal: true
require 'rspock/ast/parser/block'

module RSpock
  module AST
    module Parser
      class WhenBlock < Block
        def initialize(node)
          super(:When, node)
        end

        def can_start?
          true
        end

        def successors
          @successors ||= [:Then].freeze
        end
      end
    end
  end
end
