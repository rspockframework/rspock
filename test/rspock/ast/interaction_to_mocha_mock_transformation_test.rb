# frozen_string_literal: true
require 'test_helper'
require 'string_helper'
require 'rspock/ast/parser/interaction_parser'
require 'rspock/ast/interaction_to_mocha_mock_transformation'

module RSpock
  module AST
    class InteractionToMochaMockTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::StringHelper
      include ASTTransform::TransformationHelper

      def setup
        @transformation = InteractionToMochaMockTransformation.new
        @transformer = ASTTransform::Transformer.new
      end

      test "message without params" do
        assert_transforms(
          '1 * receiver.message',
          'receiver.expects(:message).times(1)'
        )
      end

      test "message with params" do
        assert_transforms(
          '1 * receiver.message(param1, *param2, p3: param3)',
          'receiver.expects(:message).with(param1, *param2, p3: param3).times(1)'
        )
      end

      test "chained receiver" do
        assert_transforms(
          '1 * base_object.receiver.message',
          'base_object.receiver.expects(:message).times(1)'
        )
      end

      test "any_matcher cardinality" do
        assert_transforms(
          '_ * receiver.message',
          'receiver.expects(:message).at_least(0)'
        )
      end

      test "irange cardinality" do
        assert_transforms(
          '(1..2) * receiver.message',
          'receiver.expects(:message).at_least(1).at_most(2)'
        )
      end

      test "irange with any_matcher min" do
        assert_transforms(
          '(_..2) * receiver.message',
          'receiver.expects(:message).at_least(0).at_most(2)'
        )
      end

      test "irange with any_matcher max" do
        assert_transforms(
          '(1.._) * receiver.message',
          'receiver.expects(:message).at_least(1)'
        )
      end

      test "erange cardinality" do
        assert_transforms(
          '(1...3) * receiver.message',
          'receiver.expects(:message).at_least(1).at_most(3 - 1)'
        )
      end

      test "erange with any_matcher min" do
        assert_transforms(
          '(_...3) * receiver.message',
          'receiver.expects(:message).at_least(0).at_most(3 - 1)'
        )
      end

      test "erange with any_matcher max" do
        assert_transforms(
          '(1..._) * receiver.message',
          'receiver.expects(:message).at_least(1)'
        )
      end

      test ">> stubs return value" do
        assert_transforms(
          '1 * receiver.message >> "result"',
          'receiver.expects(:message).times(1).returns("result")'
        )
      end

      test ">> with params" do
        assert_transforms(
          '1 * receiver.message(param1, param2) >> "result"',
          'receiver.expects(:message).with(param1, param2).times(1).returns("result")'
        )
      end

      test "interaction without >> has no returns" do
        result = transform('1 * receiver.message')
        refute_match(/returns/, result)
      end

      test "&block produces setup with expects and capture" do
        ir_node = parse_to_ir('1 * receiver.message("arg", &my_proc)')
        result = @transformation.run(ir_node)

        source = Unparser.unparse(result)
        assert_match(/receiver\.expects\(:message\)\.with\("arg"\)\.times\(1\)/, source)
        assert_match(/RSpock::Helpers::BlockCapture\.capture\(receiver, :message\)/, source)
      end

      test "&block without other args" do
        ir_node = parse_to_ir('1 * receiver.message(&my_proc)')
        result = @transformation.run(ir_node)

        source = Unparser.unparse(result)
        refute_match(/\.with\(/, source)
        assert_match(/receiver\.expects\(:message\)\.times\(1\)/, source)
        assert_match(/BlockCapture\.capture/, source)
      end

      test "&block with >> produces returns and capture" do
        ir_node = parse_to_ir('1 * receiver.message(&my_proc) >> "result"')
        result = @transformation.run(ir_node)

        source = Unparser.unparse(result)
        assert_match(/\.returns\("result"\)/, source)
        assert_match(/BlockCapture\.capture/, source)
      end

      test "unique index produces unique capture variable names" do
        ir_node = parse_to_ir('1 * receiver.message(&my_proc)')

        result0 = InteractionToMochaMockTransformation.new(0).run(ir_node)
        result1 = InteractionToMochaMockTransformation.new(1).run(ir_node)

        assert_match(/__rspock_blk_0/, Unparser.unparse(result0))
        assert_match(/__rspock_blk_1/, Unparser.unparse(result1))
      end

      test "non-interaction node is returned unchanged" do
        node = s(:send, 1, :==, 2)
        result = @transformation.run(node)
        assert_equal node, result
      end

      private

      def parse_to_ir(source)
        ast = @transformer.build_ast(source)
        Parser::InteractionParser.new.parse(ast)
      end

      def transform(source)
        ir_node = parse_to_ir(source)
        result = @transformation.run(ir_node)
        Unparser.unparse(result)
      end

      def assert_transforms(source, expected)
        assert_equal strip_end_line(expected + "\n"), transform(source)
      end
    end
  end
end
