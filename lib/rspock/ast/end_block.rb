# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class EndBlock < Block
      def initialize
        super(:End, nil)
      end

      def successors
        @successors ||= [].freeze
      end
    end
  end
end
