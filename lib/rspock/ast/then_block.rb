# frozen_string_literal: true
require 'rspock/ast/block'
require 'rspock/ast/then_block_transformation'

module RSpock
  module AST
    class ThenBlock < Block
      def initialize(node)
        super(:Then, node)
      end

      def successors
        @successors ||= [:Then, :Cleanup, :Where, :End].freeze
      end

      def to_children_ast
        super.map { |child| ThenBlockTransformation.new.process(child) }
      end
    end
  end
end
