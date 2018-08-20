# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class StartBlock < Block
      def initialize
        super(:Start, nil)
      end

      def successors
        @successors ||= [:Given, :When, :Then].freeze
      end
    end
  end
end
