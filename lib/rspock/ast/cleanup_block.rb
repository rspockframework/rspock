# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class CleanupBlock < Block
      def initialize(node)
        super(:Cleanup, node)
      end

      def successors
        @successors ||= [:Where, :End].freeze
      end
    end
  end
end
