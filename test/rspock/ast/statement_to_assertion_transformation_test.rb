# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/statement_to_assertion_transformation'

module RSpock
  module AST
    class StatementToAssertionTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include ASTTransform::TransformationHelper

      def setup
        @transformation = StatementToAssertionTransformation.new
      end

      # --- Binary statement: == ---

      test "#run transforms == into assert_equal(rhs, lhs)" do
        node = build_binary(:==, s(:send, nil, :actual), s(:int, 42))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_equal, s(:int, 42), s(:send, nil, :actual)), result
      end

      # --- Binary statement: != ---

      test "#run transforms != into refute_equal(rhs, lhs)" do
        node = build_binary(:!=, s(:send, nil, :actual), s(:int, 42))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :refute_equal, s(:int, 42), s(:send, nil, :actual)), result
      end

      # --- Binary statement: =~ ---

      test "#run transforms =~ into assert_match(rhs, lhs)" do
        regex = s(:regexp, s(:str, "foo"), s(:regopt))
        node = build_binary(:=~, s(:send, nil, :str), regex)

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_match, regex, s(:send, nil, :str)), result
      end

      # --- Binary statement: !~ ---

      test "#run transforms !~ into refute_match(rhs, lhs)" do
        regex = s(:regexp, s(:str, "foo"), s(:regopt))
        node = build_binary(:'!~', s(:send, nil, :str), regex)

        result = @transformation.run(node)

        assert_equal s(:send, nil, :refute_match, regex, s(:send, nil, :str)), result
      end

      # --- Binary statement: comparison operators ---

      test "#run transforms > into assert_operator(lhs, :>, rhs)" do
        node = build_binary(:>, s(:send, nil, :a), s(:int, 5))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_operator, s(:send, nil, :a), s(:sym, :>), s(:int, 5)), result
      end

      test "#run transforms < into assert_operator(lhs, :<, rhs)" do
        node = build_binary(:<, s(:send, nil, :a), s(:int, 5))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_operator, s(:send, nil, :a), s(:sym, :<), s(:int, 5)), result
      end

      test "#run transforms >= into assert_operator(lhs, :>=, rhs)" do
        node = build_binary(:>=, s(:send, nil, :a), s(:int, 5))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_operator, s(:send, nil, :a), s(:sym, :>=), s(:int, 5)), result
      end

      test "#run transforms <= into assert_operator(lhs, :<=, rhs)" do
        node = build_binary(:<=, s(:send, nil, :a), s(:int, 5))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_operator, s(:send, nil, :a), s(:sym, :<=), s(:int, 5)), result
      end

      # --- Binary statement: unknown operator fallback ---

      test "#run falls back to assert_operator for unrecognized binary operators" do
        node = build_binary(:**, s(:send, nil, :a), s(:int, 2))

        result = @transformation.run(node)

        assert_equal s(:send, nil, :assert_operator, s(:send, nil, :a), s(:sym, :**), s(:int, 2)), result
      end

      # --- General statement ---

      test "#run transforms general statement into assert_equal(true, expr, message)" do
        expr = s(:send, s(:send, nil, :obj), :valid?)
        node = build_statement(expr, "obj.valid?")

        result = @transformation.run(node)

        expected = s(:send, nil, :assert_equal,
          s(:true),
          expr,
          s(:str, 'Expected "obj.valid?" to be true')
        )
        assert_equal expected, result
      end

      # --- General statement: negation ---

      test "#run transforms negated statement into assert_equal(false, inner, message)" do
        inner = s(:send, s(:send, nil, :obj), :empty?)
        negated = s(:send, inner, :!)
        node = build_statement(negated, "!obj.empty?")

        result = @transformation.run(node)

        expected = s(:send, nil, :assert_equal,
          s(:false),
          inner,
          s(:str, 'Expected "!obj.empty?" to be false')
        )
        assert_equal expected, result
      end

      # --- Passthrough ---

      test "#run returns unknown node types unchanged" do
        node = s(:lvasgn, :x, s(:int, 1))

        result = @transformation.run(node)

        assert_equal node, result
      end

      private

      def build_binary(op, lhs, rhs)
        RSpock::AST::Node.build(:rspock_binary_statement, lhs, s(:sym, op), rhs)
      end

      def build_statement(expr, source_text)
        RSpock::AST::Node.build(:rspock_statement, expr, s(:str, source_text))
      end
    end
  end
end
