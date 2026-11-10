# typed: false
# frozen_string_literal: true

require 'ast_transform/node'

module RSpock
  module AST
    # RSpock's intermediate representation: custom node types registered on ASTTransform::Node, so
    # +s(:rspock_*, ...)+ constructs these classes with their domain accessors. They exist only between the parser
    # and TestMethodTransformation — the transformation lowers every one of them to plain Ruby nodes before
    # emission.
    class TestNode < ASTTransform::Node
      register :rspock_test

      def def_node
        children[0]
      end

      def body_node
        children[1]
      end

      def where_node
        children[2]
      end
    end

    class BodyNode < ASTTransform::Node
      register :rspock_body
    end

    class DefNode < ASTTransform::Node
      register :rspock_def

      def method_call
        children[0]
      end

      def args
        children[1]
      end
    end

    class GivenNode < ASTTransform::Node
      register :rspock_given
    end

    class WhenNode < ASTTransform::Node
      register :rspock_when
    end

    class ThenNode < ASTTransform::Node
      register :rspock_then
    end

    class ExpectNode < ASTTransform::Node
      register :rspock_expect
    end

    class CleanupNode < ASTTransform::Node
      register :rspock_cleanup
    end

    class WhereNode < ASTTransform::Node
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

    class OutcomeNode < ASTTransform::Node
    end

    class StubReturnsNode < OutcomeNode
      register :rspock_stub_returns
    end

    class StubRaisesNode < OutcomeNode
      register :rspock_stub_raises
    end

    class RaisesNode < ASTTransform::Node
      register :rspock_raises

      def exception_class
        children[0]
      end

      def capture_var
        children[1]
      end

      def capture_name
        capture_var&.children&.[](0)
      end
    end

    class InteractionNode < ASTTransform::Node
      register :rspock_interaction

      def cardinality
        children[0]
      end

      def receiver
        children[1]
      end

      def message_sym
        children[2]
      end

      def message
        message_sym.children[0]
      end

      def args
        children[3]
      end

      def outcome
        children[4]
      end

      def block_pass
        children[5]
      end
    end

    class BinaryStatementNode < ASTTransform::Node
      register :rspock_binary_statement

      def lhs
        children[0]
      end

      def operator
        children[1]
      end

      def rhs
        children[2]
      end
    end

    class StatementNode < ASTTransform::Node
      register :rspock_statement

      def expression
        children[0]
      end

      def source
        children[1]
      end
    end
  end
end
