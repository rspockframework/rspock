# frozen_string_literal: true
require 'rspock/ast/block'

module RSpock
  module AST
    class StartBlock < Block
      def initialize(node)
        super(:Start, node)
        @node_container = false
      end

      def successors
        if @children.empty?
          SUCCESSORS_WITHOUT_CHILDREN
        else
          SUCCESSORS_WITH_CHILDREN
        end
      end

      def succession_error_msg
        "Test method @ #{range} must start with one of these Blocks: #{successors}"
      end

      SUCCESSORS_WITHOUT_CHILDREN = [:Given, :When, :Expect].freeze
      SUCCESSORS_WITH_CHILDREN = [:End].freeze
    end
  end
end
