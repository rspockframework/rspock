# frozen_string_literal: true
require 'ast_transform/abstract_transformation'
require 'rspock/ast/test_method_def_transformation'
require 'rspock/ast/header_nodes_transformation'
require 'rspock/ast/method_call_to_lvar_transformation'

module RSpock
  module AST
    class TestMethodTransformation < ASTTransform::AbstractTransformation
      def initialize(source_map, start_block_class, end_block_class, strict: true)
        @source_map = source_map
        @start_block_class = start_block_class
        @end_block_class = end_block_class
        @strict = strict
        @blocks = []
      end

      def run(node)
        parse(node)
        build_ast(node)
      end

      private

      def parse(node)
        start_block = @start_block_class.new(node)
        start_block.node_container = !@strict

        add_block(start_block)
        test_method_nodes(node).each { |n| parse_node(n) }
        add_block(@end_block_class.new)
        nil
      end

      def build_ast(node)
        if where_block
          ast = s(:block,
            build_where_block_iterator(where_block.data),
            build_where_block_args(where_block.header),
            build_test_method_def(node)
          )
        else
          ast = build_test_method_def(node)
        end

        source_map_rescue_wrapper(ast)
      end

      def build_where_block_iterator(rows)
        s(:send,
          s(:send,
            s(:array, *build_where_block_data_rows(rows)),
            :each,
          ),
          :with_index
        )
      end

      def build_where_block_data_rows(rows)
        rows.map(&method(:build_where_block_data_row))
      end

      def build_where_block_data_row(row)
        children = row.dup
        children << s(:int, row.first&.loc&.expression&.line)

        s(:array, *children)
      end

      def build_where_block_args(header)
        injected_args = header.map { |column| s(:arg, column) }
        injected_args << s(:arg, :_line_number_)

        s(:args,
          s(:mlhs, *injected_args),
          s(:arg, :_test_index_),
        )
      end

      def build_test_method_def(node)
        if where_block
          ast = s(:block,
            TestMethodDefTransformation.new.run(node.children[0]),
            node.children[1],
            build_test_body
          )
          HeaderNodesTransformation.new(where_block.header).run(ast)
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
        if current_scope && !current_scope.valid_successor?(block)
          raise RSpock::AST::BlockError, current_scope.succession_error_msg
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
          current_scope << node
        end
      end

      def build_block(node)
        @source_map[node.children[1]].new(node)
      end

      def where_block
        @where_block ||= @blocks.detect { |block| block.type == :Where }
      end

      def cleanup_block
        @cleanup_block ||= @blocks.detect { |block| block.type == :Cleanup }
      end

      def build_test_body
        ensure_children = [
          s(:begin,
            *@blocks.select { |block| [:Start, :Given, :When, :Then, :Expect].include?(block.type) }
              .map { |block| block.children }.flatten)
        ]
        ensure_children << s(:begin, *cleanup_block.children) if cleanup_block

        ast = s(:kwbegin,
                s(:ensure, *ensure_children)
              )
        ast = MethodCallToLVarTransformation.new(:_test_index_, :_line_number_).run(ast)
        source_map_rescue_wrapper(ast)
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
