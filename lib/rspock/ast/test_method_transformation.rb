# frozen_string_literal: true
require 'rspock/ast/abstract_transformation'
require 'rspock/ast/test_method_def_transformation'
require 'rspock/ast/header_node_transformation'

module RSpock
  module AST
    class TestMethodTransformation < AbstractTransformation
      def initialize(source_map, start_block_class, end_block_class)
        @source_map = source_map
        @start_block_class = start_block_class
        @end_block_class = end_block_class
        @blocks = []
      end

      def process(node)
        parse(node)
        to_ast(node)
      end

      private

      def parse(node)
        add_block(@start_block_class.new)
        test_method_nodes(node).each { |node| parse_node(node) }
        add_block(@end_block_class.new)
        nil
      end

      def to_ast(node)
        if where_block
          ast = s(:block,
            build_where_block_iteration(where_block.data),
            build_where_block_args(where_block.header),
            build_test_method_def(node)
          )
        else
          ast = build_test_method_def(node)
        end

        source_map_wrapper(ast)
      end

      def build_where_block_iteration(row_nodes)
        s(:send,
          s(:send,
            s(:array, *row_nodes.map { |row| s(:array, *row) }),
            :each,
          ),
          :with_index
        )
      end

      def build_where_block_args(header)
        s(:args,
          s(:mlhs, *header.map { |column| s(:arg, column) }),
          s(:arg, :test_index),
        )
      end

      def build_test_method_def(node)
        if where_block
          ast = s(:block,
            TestMethodDefTransformation.new.run(node.children[0]),
            node.children[1],
            build_test_body
          )
          HeaderNodeTransformation.new(where_block.header).process(ast)
        else
          s(:block,
            node.children[0],
            node.children[1],
            build_test_body
          )
        end
      end

      def first_scope
        @blocks.first
      end

      def current_scope
        @blocks.last
      end

      def add_block(block)
        scope = current_scope

        if scope && !scope.successors.include?(block.type)
          raise RSpock::AST::TestClassTransformation::BlockASTError, error_msg(scope)
        end

        @blocks << block
      end

      def test_method_nodes(node)
        return [] if node.children[2].nil?

        node.children[2]&.type == :begin ? node.children[2].children : [node.children[2]]
      end

      def parse_node(node)
        if @source_map.key?(node.children[1])
          add_block(build_block(node))
        else
          scope = current_scope
          if scope.type == first_scope.type
            raise RSpock::AST::TestClassTransformation::BlockASTError,
                  "Test method must start with one of the following Blocks: #{scope.successors}"
          end

          scope.children << node
        end
      end

      def build_block(node)
        @source_map[node.children[1]].new(node)
      end

      def error_msg(scope)
        if @blocks.first && @blocks.first.type == scope.type
          "Test method must start with one of the following Blocks: #{scope.successors}"
        else
          "Block #{scope.type} @ #{scope.node.loc.line}:#{scope.node.loc.column} must be followed by one of the "\
            "following Blocks: #{scope.successors}"
        end
      end

      def where_block
        @where_block ||= @blocks.select { |block| block.type == :Where }.first
      end

      def build_test_body
        ast = s(:kwbegin,
          s(:ensure,
            s(:begin,
              *@blocks.select { |block| [:Given, :When, :Then].include?(block.type) }
                .map { |block| block.to_children_ast }.flatten,
              ),
            *@blocks.select { |block| block.type == :Cleanup }.first&.to_children_ast
          )
        )
        source_map_wrapper(ast)
      end

      def source_map_wrapper(node)
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
                        s(:cbase), :RSpock), :Backtrace), :new), :associate_to_exception,
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
