# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class GivenBlock < Block
      def initialize(node)
        super(:Given, node)
      end

      def successors
        @successors ||= [:When, :Then].freeze
      end
    end
  end
end
