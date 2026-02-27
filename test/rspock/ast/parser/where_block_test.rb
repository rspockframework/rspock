# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'ast_transform/transformation_helper'
require 'rspock/ast/parser/where_block'

module RSpock
  module AST
    module Parser
      class WhereBlockTest < Minitest::Test
        extend RSpock::Declarative
        include RSpock::Helpers::TransformationHelper

        def setup
          @block = RSpock::AST::Parser::WhereBlock.new(nil)
        end

        test "#can_start? returns false" do
          assert_equal false, @block.can_start?
        end

        test "#can_end? returns true" do
          assert_equal true, @block.can_end?
        end

        test "#type is :Where" do
          assert_equal :Where, @block.type
        end

        test "#header with a single send ast node returns that node's symbol" do
          @block << s(:send, nil, :a)

          assert_equal [:a], @block.header
        end

        test "#header separated by pipes returns each node's symbol" do
          @block << s(:send,
                      s(:send,
                        s(:send, nil, :a), :|, s(:send, nil, :b)
                      ),
                      :|, s(:send, nil, :c))

          assert_equal [:a, :b, :c], @block.header
        end

        test "#header with a single send ast node must be a header node" do
          @block << s(:str, "potato")

          assert_raises RSpock::AST::Parser::WhereBlock::MalformedError do
            @block.header
          end
        end

        test "#header terminal nodes must be header nodes" do
          @block << s(:send,
                               s(:str, "potato"), :|, s(:send, nil, :b))

          assert_raises RSpock::AST::Parser::WhereBlock::MalformedError do
            @block.header
          end
        end

        test "#data with a single data node returns that data node" do
          @block << s(:send, nil, :a)
          @block << s(:int, 1)

          assert_equal [[s(:int, 1)]], @block.data
        end

        test "#data without data nodes returns an empty array" do
          @block << s(:send, nil, :a)

          assert_equal [], @block.data
        end

        test "#data with multiple rows returns multiple rows" do
          @block << s(:send, nil, :a)
          @block << s(:int, 1)
          @block << s(:int, 2)

          expected = [
            [s(:int, 1)],
            [s(:int, 2)]
          ]

          assert_equal expected, @block.data
        end

        test "#data pipes returns a flattened array of nodes" do
          @block << s(:send, nil, :a)
          @block << s(:send, s(:int, 1), :|, s(:int, 2))
          @block << s(:send, s(:send, s(:int, 1), :|, s(:int, 2)), :|, s(:send, nil, :method_call))

          expected = [
            [s(:int, 1), s(:int, 2)],
            [s(:int, 1), s(:int, 2), s(:send, nil, :method_call)],
          ]

          assert_equal expected, @block.data
        end

        test "#data pipes works when subtracting from nodes" do
          @block << s(:send, s(:send, nil, :a), :|, s(:send, nil, :b))
          @block << s(:send, s(:send, s(:int, 2), :-, s(:int, 1)), :|, s(:int, 2))

          expected = [
            [ s(:send, s(:int, 2), :-, s(:int, 1)), s(:int, 2)],
          ]

          assert_equal expected, @block.data
        end

        test "#to_rspock_node returns a self-contained :rspock_where node" do
          @block << s(:send, s(:send, nil, :a), :|, s(:send, nil, :b))
          @block << s(:send, s(:int, 1), :|, s(:int, 2))
          @block << s(:send, s(:int, 3), :|, s(:int, 4))

          node = @block.to_rspock_node

          assert_equal :rspock_where, node.type

          header_node = node.children[0]
          assert_equal :rspock_where_header, header_node.type
          assert_equal [s(:sym, :a), s(:sym, :b)], header_node.children

          data_rows = node.children[1..]
          assert_equal 2, data_rows.length
          assert_equal s(:array, s(:int, 1), s(:int, 2)), data_rows[0]
          assert_equal s(:array, s(:int, 3), s(:int, 4)), data_rows[1]
        end

        test "#to_rspock_node with single column" do
          @block << s(:send, nil, :a)
          @block << s(:int, 1)

          node = @block.to_rspock_node

          assert_equal :rspock_where, node.type
          assert_equal s(:rspock_where_header, s(:sym, :a)), node.children[0]
          assert_equal [s(:array, s(:int, 1))], node.children[1..]
        end
      end
    end
  end
end
