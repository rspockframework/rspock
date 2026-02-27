# frozen_string_literal: true
require 'rspock/ast/parser/block'

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
      end
    end
  end
end
