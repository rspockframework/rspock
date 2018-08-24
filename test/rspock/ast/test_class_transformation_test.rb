# frozen_string_literal: true
require 'test_helper'
require 'unparser'
require 'rspock/ast/test_class_transformation'
require 'rspock/transformer'
require 'parser/current'

module RSpock
  module AST
    class TestClassTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::AST::TransformationHelper

      def setup
        @transformation = RSpock::AST::TestClassTransformation.new
      end

      test "empty test block raises" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            
          end
        HEREDOC

        error = assert_raises RSpock::AST::TestClassTransformation::BlockASTError do
          transform(source)
        end

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Expect]}", error.message
      end

      test "first node cannot be regular code" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            b = 2
          end
        HEREDOC

        error = assert_raises RSpock::AST::TestClassTransformation::BlockASTError do
          transform(source)
        end

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Expect]}", error.message
      end

      test "first node cannot be a non-starting block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Cleanup "cleanup stuff"
          end
        HEREDOC

        error = assert_raises RSpock::AST::TestClassTransformation::BlockASTError do
          transform(source)
        end

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Expect]}", error.message
      end

      test "expect block can be followed by nothing" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Expect "do stuff"
          end
        HEREDOC

        transform(source)
      end

      test "expect block can be followed by a cleanup block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Expect "do something"
            Cleanup "cleanup stuff"
          end
        HEREDOC

        transform(source)
      end

      test "does not raise if block is followed by a legal block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Block1
            Block2
          end
        HEREDOC

        start_block_class = Class.new(RSpock::AST::Block) do
          def initialize
            super(:Start1, nil)
          end

          def successors
            [:Block1, :Block2]
          end
        end

        block1_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block1, node)
          end

          def successors
            [:Block2]
          end
        end

        block2_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block2, node)
          end
        end

        source_map = { Block1: block1_class, Block2: block2_class }

        transform(
          source,
          RSpock::AST::TestClassTransformation.new(start_block_class: start_block_class, source_map: source_map),
        )
      end

      test "raises if block is followed by an illegal block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Block1
            Block2
          end
        HEREDOC

        start_block_class = Class.new(RSpock::AST::Block) do
          def initialize
            super(:Start1, nil)
          end

          def successors
            [:Block1, :Block2]
          end
        end

        block1_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block1, node)
          end
        end

        block2_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block2, node)
          end
        end

        source_map = { Block1: block1_class, Block2: block2_class }

        assert_raises RSpock::AST::TestClassTransformation::BlockASTError do
          transform(
            source,
            RSpock::AST::TestClassTransformation.new(start_block_class: start_block_class, source_map: source_map),
          )
        end
      end

      test "#run removes include and break when using Class.new" do
        source = <<~HEREDOC
          Potato = Class.new do
            include RSpock; break
          end
        HEREDOC

        expected = <<~HEREDOC
          Potato = Class.new do
            extend(RSpock::Declarative)
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "#run removes include when using Class.new" do
        source = <<~HEREDOC
          Potato = Class.new do
            include RSpock
          end
        HEREDOC

        expected = <<~HEREDOC
          Potato = Class.new do
            extend(RSpock::Declarative)
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "#run removes include when using traditional class definition" do
        source = <<~HEREDOC
          class Potato
            include RSpock
          end
        HEREDOC

        expected = <<~HEREDOC
          class Potato
            extend(RSpock::Declarative)
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "raises if block is followed by an illegal block when code is inside a Class" do
        source = <<~HEREDOC
          class Potato
            include RSpock

            test "Adding \#{a} and \#{b} results in \#{c}" do
              Block1
              Block2
            end
          end
        HEREDOC

        start_block_class = Class.new(RSpock::AST::Block) do
          def initialize
            super(:Start1, nil)
          end

          def successors
            [:Block1, :Block2]
          end
        end

        block1_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block1, node)
          end
        end

        block2_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Block2, node)
          end
        end

        source_map = { Block1: block1_class, Block2: block2_class }

        assert_raises RSpock::AST::TestClassTransformation::BlockASTError do
          transform(
            source,
            RSpock::AST::TestClassTransformation.new(start_block_class: start_block_class, source_map: source_map),
          )
        end
      end

      test "test without where block" do
        source = <<~HEREDOC
          test "Adding 1 and 2 results in 3" do
            When "adding a and b together"
            actual = 1 + 2

            Then "we get the expected result"
            actual == 3
          end
        HEREDOC

        expected = <<~HEREDOC
          begin
            test(\"Adding 1 and 2 results in 3\") do
              begin
                begin
                  actual = (1 + 2)
                  assert_equal(3, actual)
                ensure
                end
              rescue StandardError => e
                ::RSpock::Backtrace.new.associate_to_exception(e)
                raise
              end
            end
          rescue StandardError => e
            ::RSpock::Backtrace.new.associate_to_exception(e)
            raise
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "test with where block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            When "adding a and b together"
            actual = a + b

            Then "we get the expected result"
            actual == c

            Where
            a | b | c
            1 | 2 | 3
            4 | 5 | 9
          end
        HEREDOC

        expected = <<~HEREDOC
          begin
            [[1, 2, 3], [4, 5, 9]].each.with_index do |(a, b, c), test_index|
              test(\"\#{test_index}\#{\"Adding \"}\#{a}\#{\" and \"}\#{b}\#{\" results in \"}\#{c}\") do
                begin
                  begin
                    actual = (a + b)
                    assert_equal(c, actual)
                  ensure
                  end
                rescue StandardError => e
                  ::RSpock::Backtrace.new.associate_to_exception(e)
                  raise
                end
              end
            end
          rescue StandardError => e
            ::RSpock::Backtrace.new.associate_to_exception(e)
            raise
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      private

      def transform(source, *transformations)
        transformations << @transformation if transformations.empty?

        Transformer.new(*transformations).transform(source)
      end

      def strip_end_line(str)
        str.gsub(/\n$/, '')
      end
    end
  end
end
