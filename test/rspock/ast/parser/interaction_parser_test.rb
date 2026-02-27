# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/interaction_parser'

module RSpock
  module AST
    module Parser
      class InteractionParserTest < Minitest::Test
        extend RSpock::Declarative
        include ASTTransform::TransformationHelper

        def setup
          @transformer = ASTTransform::Transformer.new
          @parser = InteractionParser.new
        end

        # --- interaction_node? ---

        test "#interaction_node? returns true for basic interaction" do
          ast = build_ast('1 * receiver.message')
          assert @parser.interaction_node?(ast)
        end

        test "#interaction_node? returns true for >> interaction" do
          ast = build_ast('1 * receiver.message >> "result"')
          assert @parser.interaction_node?(ast)
        end

        test "#interaction_node? returns false for non-interaction" do
          ast = build_ast('1 + 2')
          refute @parser.interaction_node?(ast)
        end

        test "#interaction_node? returns false for nil" do
          refute @parser.interaction_node?(nil)
        end

        test "#interaction_node? returns false for bare >>" do
          ast = build_ast('result >> "value"')
          refute @parser.interaction_node?(ast)
        end

        # --- parse: basic structure ---

        test "#parse returns :rspock_interaction node" do
          ast = build_ast('1 * receiver.message')
          ir = @parser.parse(ast)

          assert_equal :rspock_interaction, ir.type
          assert_equal 6, ir.children.length
        end

        test "#parse returns node unchanged for non-interaction" do
          ast = build_ast('1 + 2')
          result = @parser.parse(ast)
          assert_equal ast, result
        end

        # --- parse: cardinality ---

        test "#parse extracts integer cardinality" do
          ir = parse('1 * receiver.message')
          assert_equal s(:int, 1), ir.children[0]
        end

        test "#parse extracts _ any matcher cardinality" do
          ir = parse('_ * receiver.message')
          assert_equal s(:send, nil, :_), ir.children[0]
        end

        test "#parse extracts irange cardinality" do
          ir = parse('(1..3) * receiver.message')
          cardinality = ir.children[0]
          assert_equal :begin, cardinality.type
          assert_equal :irange, cardinality.children[0].type
        end

        test "#parse extracts erange cardinality" do
          ir = parse('(1...3) * receiver.message')
          cardinality = ir.children[0]
          assert_equal :begin, cardinality.type
          assert_equal :erange, cardinality.children[0].type
        end

        # --- parse: receiver and message ---

        test "#parse extracts receiver" do
          ir = parse('1 * receiver.message')
          assert_equal s(:send, nil, :receiver), ir.children[1]
        end

        test "#parse extracts message as symbol" do
          ir = parse('1 * receiver.message')
          assert_equal s(:sym, :message), ir.children[2]
        end

        test "#parse extracts chained receiver" do
          ir = parse('1 * base.receiver.message')
          receiver = ir.children[1]
          assert_equal :send, receiver.type
          assert_equal :receiver, receiver.children[1]
        end

        # --- parse: arguments ---

        test "#parse sets args to nil when no arguments" do
          ir = parse('1 * receiver.message')
          assert_nil ir.children[3]
        end

        test "#parse wraps args in :array node" do
          ir = parse('1 * receiver.message(param1, param2)')
          args = ir.children[3]
          assert_equal :array, args.type
          assert_equal 2, args.children.length
        end

        # --- parse: outcome ---

        test "#parse sets outcome to nil without >>" do
          ir = parse('1 * receiver.message')
          assert_nil ir.outcome
        end

        test "#parse wraps >> value in :rspock_returns" do
          ir = parse('1 * receiver.message >> "result"')
          assert_equal :rspock_returns, ir.outcome.type
          assert_equal s(:str, "result"), ir.outcome.children[0]
        end

        test "#parse wraps >> raises(ExClass) in :rspock_raises" do
          ir = parse('1 * receiver.message >> raises(SomeError)')
          assert_equal :rspock_raises, ir.outcome.type
          assert_equal :const, ir.outcome.children[0].type
        end

        test "#parse wraps >> raises(ExClass, msg) in :rspock_raises with two children" do
          ir = parse('1 * receiver.message >> raises(SomeError, "oops")')
          assert_equal :rspock_raises, ir.outcome.type
          assert_equal 2, ir.outcome.children.length
          assert_equal :const, ir.outcome.children[0].type
          assert_equal s(:str, "oops"), ir.outcome.children[1]
        end

        # --- parse: block pass ---

        test "#parse sets block_pass to nil without &" do
          ir = parse('1 * receiver.message')
          assert_nil ir.children[5]
        end

        test "#parse extracts &block_pass" do
          ir = parse('1 * receiver.message(&my_proc)')
          block_pass = ir.children[5]
          assert_equal :block_pass, block_pass.type
        end

        test "#parse separates &block from regular args" do
          ir = parse('1 * receiver.message("arg", &my_proc)')
          args = ir.children[3]
          block_pass = ir.children[5]

          assert_equal 1, args.children.length
          assert_equal :block_pass, block_pass.type
        end

        # --- parse: errors ---

        test "#parse raises on inline do...end block" do
          ast = build_ast('1 * receiver.message("arg") do; end')
          e = assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
          assert_match(/Inline blocks/, e.message)
        end

        test "#parse raises on inline { } block" do
          ast = build_ast('1 * receiver.message("arg") { }')
          e = assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
          assert_match(/Inline blocks/, e.message)
        end

        test "#parse raises on rhs without receiver" do
          ast = build_ast('1 * message')
          e = assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
          assert_match(/must have a receiver/, e.message)
        end

        test "#parse raises on invalid cardinality" do
          ast = build_ast('"abc" * receiver.message')
          assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
        end

        test "#parse raises on begin with multiple children" do
          ast = build_ast('(1; 2) * receiver.message')
          assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
        end

        test "#parse raises on irange with invalid min" do
          ast = build_ast('("abc"..2) * receiver.message')
          assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
        end

        test "#parse raises on irange with invalid max" do
          ast = build_ast('(1.."abc") * receiver.message')
          assert_raises InteractionParser::InteractionError do
            @parser.parse(ast)
          end
        end

        private

        def build_ast(source)
          @transformer.build_ast(source)
        end

        def parse(source)
          @parser.parse(build_ast(source))
        end
      end
    end
  end
end
