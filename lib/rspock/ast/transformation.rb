# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/parser/given_block'
require 'rspock/ast/parser/when_block'
require 'rspock/ast/parser/then_block'
require 'rspock/ast/parser/expect_block'
require 'rspock/ast/parser/cleanup_block'
require 'rspock/ast/parser/where_block'
require 'rspock/ast/test_method_transformation'

module RSpock
  module AST
    class Transformation < ASTTransform::AbstractTransformation
      DEFAULT_BLOCK_REGISTRY = {
        Given: Parser::GivenBlock,
        When: Parser::WhenBlock,
        Then: Parser::ThenBlock,
        Expect: Parser::ExpectBlock,
        Cleanup: Parser::CleanupBlock,
        Where: Parser::WhereBlock,
      }.freeze

      def initialize(
        block_registry: DEFAULT_BLOCK_REGISTRY,
        strict: true
      )
        super()
        @block_registry = block_registry
        @strict = strict
      end

      EXTEND_RSPOCK_DECLARATIVE = s(:send, nil, :extend,
                                     s(:const,
                                       s(:const, nil, :RSpock), :Declarative))

      def on_class(node)
        if node.children[2]&.type == :begin
          children = node.children.dup
          children[2] = process_rspock(children[2])

          node.updated(nil, children)
        else
          children = node.children.dup
          children[2] = process_rspock(s(:begin, node.children[2]))

          node.updated(nil, children)
        end
      end

      def on_casgn(node)
        if node.children[2]&.type == :block
          children = node.children.dup
          children[2] = process_casgn_block(children[2])

          node.updated(nil, children)
        else
          super
        end
      end

      def process_casgn_block(node)
        if node.children[2]&.type == :begin
          children = node.children.dup
          children[2] = process_rspock(children[2])

          # Optimization to remove empty :begin node
          children.slice!(2) if children[2].children.empty?

          node.updated(nil, children)
        else
          children = node.children.dup
          children[2] = process_rspock(s(:begin, node.children[2]))

          node.updated(nil, children)
        end
      end

      def process_rspock(node)
        processed = process_all(node).compact
        children = [source_map_rescue_wrapper(s(:begin, *[EXTEND_RSPOCK_DECLARATIVE, *processed]))]
        node.updated(nil, children)
      end

      def on_block(node)
        if node.children[0]&.children[1] != :test
          return node.updated(nil, process_all(node))
        end

        TestMethodTransformation.new(
          @block_registry,
          strict: @strict
        ).run(node)
      end

      def source_map_rescue_wrapper(node)
        s(:kwbegin,
          s(:rescue,
            node,
            s(:resbody,
              s(:array,
                s(:const, nil, :StandardError)
              ),
              s(:lvasgn, :e),
              s(:begin,
                s(:send,
                  s(:send,
                    s(:const,
                      s(:const,
                        s(:cbase), :RSpock), :BacktraceFilter), :new), :filter_exception,
                  s(:lvar, :e)
                ),
                s(:send, nil, :raise)
              )
            ),
            nil
          )
        )
      end
    end
  end
end
