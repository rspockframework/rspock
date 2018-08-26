# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class StartBlock < Block
      def initialize(node)
        super(:Start, node)
      end

      def successors
        @successors ||= [:Given, :When, :Expect].freeze
      end
    end
  end
end
