# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/node'
require 'rspock/ast/statement_to_assertion_transformation'
require 'rspock/ast/header_nodes_transformation'
require 'rspock/ast/interaction_to_mocha_mock_transformation'
require 'rspock/ast/interaction_to_block_identity_assertion_transformation'
require 'rspock/ast/method_call_to_lvar_transformation'
require 'rspock/ast/test_method_def_transformation'
require 'rspock/ast/parser/test_method_parser'

module RSpock
  module AST
    class TestMethodTransformation < ASTTransform::AbstractTransformation
      def initialize(block_registry, strict: true)
        @parser = Parser::TestMethodParser.new(block_registry, strict: strict)
        @statement_transformation = StatementToAssertionTransformation.new
      end

      def run(node)
        rspock_ast = @parser.parse(node)
        return node if rspock_ast.nil?
        transform(rspock_ast)
      end

      private

      def transform(rspock_ast)
        hoisted_setups = []

        method_call = rspock_ast.def_node.method_call
        method_args = rspock_ast.def_node.args
        where = rspock_ast.where_node

        transformed_blocks = rspock_ast.body_node.children.map do |block_node|
          case block_node.type
          when :rspock_then
            transform_then_block(block_node, hoisted_setups)
          when :rspock_expect
            transform_expect_block(block_node)
          else
            block_node
          end
        end

        transformed_body = rspock_ast.body_node.updated(nil, transformed_blocks)
        build_ruby_ast(method_call, method_args, transformed_body, where, hoisted_setups)
      end

      def transform_then_block(then_node, hoisted_setups)
        interaction_setups = []
        then_children = []

        then_node.children.each_with_index do |child, idx|
          if child.type == :rspock_interaction
            setup = InteractionToMochaMockTransformation.new(idx).run(child)
            assertion = InteractionToBlockIdentityAssertionTransformation.new(idx).run(child)

            interaction_setups << setup
            then_children << assertion unless assertion.equal?(child)
          else
            then_children << transform_statement_or_passthrough(child)
          end
        end

        unless interaction_setups.empty?
          interaction_setups.each do |node|
            if node.type == :begin
              hoisted_setups.concat(node.children)
            else
              hoisted_setups << node
            end
          end
        end

        then_node.updated(nil, then_children)
      end

      def transform_expect_block(expect_node)
        new_children = expect_node.children.map { |child| transform_statement_or_passthrough(child) }
        expect_node.updated(nil, new_children)
      end

      def transform_statement_or_passthrough(child)
        case child.type
        when :rspock_binary_statement, :rspock_statement
          @statement_transformation.run(child)
        else
          child
        end
      end

      # --- Build final Ruby AST ---

      def build_ruby_ast(method_call, method_args, body_node, where, hoisted_setups)
        if where
          test_def = s(:block,
            TestMethodDefTransformation.new.run(method_call),
            method_args,
            build_test_body(body_node, hoisted_setups)
          )
          test_def = HeaderNodesTransformation.new(where.header).run(test_def)

          s(:block,
            build_where_iterator(where.data_rows),
            build_where_args(where.header),
            test_def
          )
        else
          s(:block,
            method_call,
            method_args,
            build_test_body(body_node, hoisted_setups)
          )
        end
      end

      def build_test_body(body_node, hoisted_setups)
        body_children = []

        body_node.children.each do |block_node|
          case block_node.type
          when :rspock_given
            body_children.concat(block_node.children)
          when :rspock_when
            body_children.concat(hoisted_setups)
            body_children.concat(block_node.children)
          when :rspock_then, :rspock_expect
            body_children.concat(block_node.children)
          when :rspock_cleanup
            # handled below as ensure
          end
        end

        ast = s(:begin, *body_children)

        cleanup = body_node.children.find { |n| n.type == :rspock_cleanup }
        if cleanup && !cleanup.children.empty?
          ensure_node = s(:begin, *cleanup.children)
          ast = s(:kwbegin, s(:ensure, ast, ensure_node))
        end

        MethodCallToLVarTransformation.new(:_test_index_, :_line_number_).run(ast)
      end

      # --- Where block helpers ---

      def build_where_iterator(data_rows)
        s(:send,
          s(:send,
            s(:array, *data_rows.map { |row| build_where_data_row(row) }),
            :each,
          ),
          :with_index
        )
      end

      def build_where_data_row(row)
        children = row.dup
        children << s(:int, row.first&.loc&.expression&.line)
        s(:array, *children)
      end

      def build_where_args(header)
        injected_args = header.map { |column| s(:arg, column) }
        injected_args << s(:arg, :_line_number_)
        s(:args,
          s(:mlhs, *injected_args),
          s(:arg, :_test_index_),
        )
      end
    end
  end
end
