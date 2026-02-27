# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/parser/interaction_parser'
require 'rspock/ast/interaction_to_block_identity_assertion_transformation'

module RSpock
  module AST
    class InteractionToBlockIdentityAssertionTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include ASTTransform::TransformationHelper

      test "#run returns passthrough for interaction without &block" do
        source = '1 * receiver.message("arg")'
        ir_node = parse_to_ir(source)

        result = InteractionToBlockIdentityAssertionTransformation.new(0).run(ir_node)
        assert result.equal?(ir_node), "expected passthrough (same object identity)"
      end

      test "#run returns assert_same node for interaction with &block" do
        source = '1 * receiver.message("arg", &my_proc)'
        ir_node = parse_to_ir(source)

        result = InteractionToBlockIdentityAssertionTransformation.new(0).run(ir_node)
        refute result.equal?(ir_node)

        expected = s(:send, nil, :assert_same,
          s(:send, nil, :my_proc),
          s(:send, s(:lvar, :__rspock_blk_0), :call)
        )
        assert_equal expected, result
      end

      test "#run uses index for unique variable names" do
        source = '1 * receiver.message(&callback)'
        ir_node = parse_to_ir(source)

        result = InteractionToBlockIdentityAssertionTransformation.new(2).run(ir_node)

        expected = s(:send, nil, :assert_same,
          s(:send, nil, :callback),
          s(:send, s(:lvar, :__rspock_blk_2), :call)
        )
        assert_equal expected, result
      end

      test "#run returns passthrough for >> interaction without &block" do
        source = '1 * receiver.message >> "result"'
        ir_node = parse_to_ir(source)

        result = InteractionToBlockIdentityAssertionTransformation.new(0).run(ir_node)
        assert result.equal?(ir_node), "expected passthrough (same object identity)"
      end

      test "#run returns assertion for >> interaction with &block" do
        source = '1 * receiver.message(&my_proc) >> "result"'
        ir_node = parse_to_ir(source)

        result = InteractionToBlockIdentityAssertionTransformation.new(0).run(ir_node)
        refute result.equal?(ir_node)

        expected = s(:send, nil, :assert_same,
          s(:send, nil, :my_proc),
          s(:send, s(:lvar, :__rspock_blk_0), :call)
        )
        assert_equal expected, result
      end

      test "#run returns node unchanged for non-interaction nodes" do
        node = s(:send, 1, :==, 2)
        result = InteractionToBlockIdentityAssertionTransformation.new(0).run(node)
        assert_equal node, result
      end

      private

      def parse_to_ir(source)
        ast = ASTTransform::Transformer.new.build_ast(source)
        Parser::InteractionParser.new.parse(ast)
      end
    end
  end
end
