# frozen_string_literal: true
module RSpock
  module AST
    class Block
      def initialize(type, node)
        @type = type
        @node = node
        @children = []
      end

      attr_accessor :children
      attr_reader :type, :node

      def successors
        @successors ||= [:End].freeze
      end

      def to_children_ast
        @children.dup
      end
    end
  end
end
