# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class WhenBlock < Block
      def initialize(node)
        super(:When, node)
      end

      def successors
        @successors ||= [:Then].freeze
      end
    end
  end
end
