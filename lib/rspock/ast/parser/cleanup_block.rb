# frozen_string_literal: true
require 'rspock/ast/parser/block'

module RSpock
  module AST
    module Parser
      class CleanupBlock < Block
        def initialize(node)
          super(:Cleanup, node)
        end

        def can_end?
          true
        end

        def successors
          @successors ||= [:Where].freeze
        end
      end
    end
  end
end
