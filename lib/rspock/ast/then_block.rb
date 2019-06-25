# frozen_string_literal: true
require 'rspock/ast/block'
require 'rspock/ast/comparison_to_assertion_transformation'
require 'rspock/ast/interaction_transformation'

module RSpock
  module AST
    class ThenBlock < Block
      def initialize(node)
        super(:Then, node)
      end

      def successors
        @successors ||= [:Cleanup, :Where, :End].freeze
      end

      def children
        super.reject { |child| interaction_transformation.interaction_node?(child) }
          .map { |child| ComparisonToAssertionTransformation.new(:_test_index_, :_line_number_).run(child) }
      end

      def interactions
        @children.select { |child| interaction_transformation.interaction_node?(child) }
          .map { |child| interaction_transformation.run(child) }
      end

      private

      def interaction_transformation
        @interaction_transformation ||= RSpock::AST::InteractionTransformation.new
      end
    end
  end
end
