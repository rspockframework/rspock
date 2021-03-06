# frozen_string_literal: true
require 'rspock/ast/block'
require 'rspock/ast/comparison_to_assertion_transformation'

module RSpock
  module AST
    class ExpectBlock < Block
      def initialize(node)
        super(:Expect, node)
      end

      def successors
        @successors ||= [:Cleanup, :Where, :End].freeze
      end

      def children
        super.map { |child| ComparisonToAssertionTransformation.new(:_test_index_, :_line_number_).run(child) }
      end
    end
  end
end
