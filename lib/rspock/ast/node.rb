# frozen_string_literal: true
require 'ast_transform/transformation_helper'

module RSpock
  module AST
    class Node < ::Parser::AST::Node
      REGISTRY = {}

      def self.register(type)
        REGISTRY[type] = self
      end

      def self.build(type, *children)
        klass = REGISTRY[type] || self
        klass.new(type, children)
      end
    end

    class TestNode < Node
      register :rspock_test

      def def_node   = children[0]
      def body_node  = children[1]
      def where_node = children[2]
    end

    class BodyNode < Node
      register :rspock_body
    end

    class DefNode < Node
      register :rspock_def

      def method_call = children[0]
      def args        = children[1]
    end

    class GivenNode < Node
      register :rspock_given
    end

    class WhenNode < Node
      register :rspock_when
    end

    class ThenNode < Node
      register :rspock_then
    end

    class ExpectNode < Node
      register :rspock_expect
    end

    class CleanupNode < Node
      register :rspock_cleanup
    end

    class WhereNode < Node
      register :rspock_where

      def header
        header_node = children.find { |n| n.type == :rspock_where_header }
        header_node.children.map { |sym_node| sym_node.children[0] }
      end

      def data_rows
        children
          .select { |n| n.type == :array }
          .map(&:children)
      end
    end

    class OutcomeNode < Node
    end

    class ReturnsNode < OutcomeNode
      register :rspock_returns
    end

    class RaisesNode < OutcomeNode
      register :rspock_raises
    end

    class InteractionNode < Node
      register :rspock_interaction

      def cardinality  = children[0]
      def receiver     = children[1]
      def message_sym  = children[2]
      def message      = message_sym.children[0]
      def args         = children[3]
      def outcome      = children[4]
      def block_pass   = children[5]
    end

    class BinaryStatementNode < Node
      register :rspock_binary_statement

      def lhs      = children[0]
      def operator = children[1]
      def rhs      = children[2]
    end

    class StatementNode < Node
      register :rspock_statement

      def expression = children[0]
      def source     = children[1]
    end

    module NodeBuilder
      include ASTTransform::TransformationHelper

      def s(type, *children)
        if type.to_s.start_with?('rspock_')
          Node.build(type, *children)
        else
          super
        end
      end
    end
  end
end
