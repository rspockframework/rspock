# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/statement_parser'

module RSpock
  module AST
    module Parser
      class StatementParserTest < Minitest::Test
        extend RSpock::Declarative
        include ASTTransform::TransformationHelper

        def setup
          @transformer = ASTTransform::Transformer.new
          @parser = StatementParser.new
        end

        # --- Assignments pass through ---

        test "#parse returns lvasgn node unchanged" do
          ast = build_ast('x = 1')
          result = @parser.parse(ast)

          assert_equal ast, result
          assert_equal :lvasgn, result.type
        end

        test "#parse returns masgn node unchanged" do
          ast = build_ast('a, b = 1, 2')
          result = @parser.parse(ast)

          assert_equal ast, result
          assert_equal :masgn, result.type
        end

        test "#parse returns op_asgn node unchanged" do
          ast = build_ast('x += 1')
          result = @parser.parse(ast)

          assert_equal ast, result
          assert_equal :op_asgn, result.type
        end

        test "#parse returns or_asgn node unchanged" do
          ast = build_ast('x ||= 1')
          result = @parser.parse(ast)

          assert_equal ast, result
          assert_equal :or_asgn, result.type
        end

        test "#parse returns and_asgn node unchanged" do
          ast = build_ast('x &&= 1')
          result = @parser.parse(ast)

          assert_equal ast, result
          assert_equal :and_asgn, result.type
        end

        # --- Binary operators ---

        test "#parse wraps == in :rspock_binary_statement" do
          ast = build_ast('a == b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :==), result.operator
        end

        test "#parse wraps != in :rspock_binary_statement" do
          ast = build_ast('a != b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :!=), result.operator
        end

        test "#parse wraps =~ in :rspock_binary_statement" do
          ast = build_ast('a =~ /foo/')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :=~), result.operator
        end

        test "#parse wraps !~ in :rspock_binary_statement" do
          ast = build_ast('a !~ /foo/')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :'!~'), result.operator
        end

        test "#parse wraps > in :rspock_binary_statement" do
          ast = build_ast('a > b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :>), result.operator
        end

        test "#parse wraps < in :rspock_binary_statement" do
          ast = build_ast('a < b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :<), result.operator
        end

        test "#parse wraps >= in :rspock_binary_statement" do
          ast = build_ast('a >= b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :>=), result.operator
        end

        test "#parse wraps <= in :rspock_binary_statement" do
          ast = build_ast('a <= b')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:sym, :<=), result.operator
        end

        test "#parse extracts lhs and rhs for binary statement" do
          ast = build_ast('a == 42')
          result = @parser.parse(ast)

          assert_equal :rspock_binary_statement, result.type
          assert_equal s(:send, nil, :a), result.lhs
          assert_equal s(:int, 42), result.rhs
        end

        # --- General statements ---

        test "#parse wraps method call in :rspock_statement" do
          ast = build_ast('obj.valid?')
          result = @parser.parse(ast)

          assert_equal :rspock_statement, result.type
          assert_equal ast, result.expression
        end

        test "#parse wraps negated expression in :rspock_statement" do
          ast = build_ast('!obj.empty?')
          result = @parser.parse(ast)

          assert_equal :rspock_statement, result.type
          assert_equal ast, result.expression
        end

        test "#parse captures source text in :rspock_statement" do
          ast = build_ast('obj.valid?')
          result = @parser.parse(ast)

          assert_equal :str, result.source.type
          assert_equal 'obj.valid?', result.source.children[0]
        end

        test "#parse captures source text for negated expression" do
          ast = build_ast('!obj.empty?')
          result = @parser.parse(ast)

          assert_equal '!obj.empty?', result.source.children[0]
        end

        test "#parse wraps bare identifier in :rspock_statement" do
          ast = build_ast('result')
          result = @parser.parse(ast)

          assert_equal :rspock_statement, result.type
        end

        # --- Does not classify non-binary sends as binary ---

        test "#parse does not treat method call with args as binary statement" do
          ast = build_ast('obj.include?("foo")')
          result = @parser.parse(ast)

          assert_equal :rspock_statement, result.type
        end

        private

        def build_ast(source)
          @transformer.build_ast(source)
        end
      end
    end
  end
end
