# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/start_block'
require 'rspock/ast/given_block'
require 'rspock/ast/when_block'
require 'rspock/ast/then_block'
require 'rspock/ast/expect_block'
require 'rspock/ast/cleanup_block'
require 'rspock/ast/where_block'
require 'rspock/ast/end_block'
require 'rspock/ast/test_method_transformation'

module RSpock
  module AST
    class Transformation < ASTTransform::AbstractTransformation
      DefaultSourceMap = {
        Given: RSpock::AST::GivenBlock,
        When: RSpock::AST::WhenBlock,
        Then: RSpock::AST::ThenBlock,
        Expect: RSpock::AST::ExpectBlock,
        Cleanup: RSpock::AST::CleanupBlock,
        Where: RSpock::AST::WhereBlock,
      }.freeze

      def initialize(
        start_block_class: StartBlock,
        end_block_class: EndBlock,
        source_map: DefaultSourceMap,
        strict: true
      )
        super()
        @start_block_class = start_block_class
        @source_map = source_map
        @end_block_class = end_block_class
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
          @source_map,
          @start_block_class,
          @end_block_class,
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
