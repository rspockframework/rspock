# frozen_string_literal: true
require 'rspock/ast/parser/block'

module RSpock
  module AST
    module Parser
      class GivenBlock < Block
        def initialize(node)
          super(:Given, node)
        end

        def can_start?
          true
        end

        def successors
          @successors ||= [:When, :Expect].freeze
        end
      end
    end
  end
end
