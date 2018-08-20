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

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Then]}", error.message
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

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Then]}", error.message
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

        assert_equal "Test method must start with one of the following Blocks: #{[:Given, :When, :Then]}", error.message
      end

      test "then block can be followed by nothing" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Then "do stuff"
          end
        HEREDOC

        transform(source)
      end

      test "then block cannot be followed by a cleanup block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Then "do something"
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

      test "#process removes include and break when using Class.new" do
        source = <<~HEREDOC
          Potato = Class.new do
            include RSpock; break
          end
        HEREDOC

        expected = <<~HEREDOC
          Potato = Class.new do
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "#process removes include when using Class.new" do
        source = <<~HEREDOC
          Potato = Class.new do
            include RSpock
          end
        HEREDOC

        expected = <<~HEREDOC
          Potato = Class.new do
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "#process removes include when using traditional class definition" do
        source = <<~HEREDOC
          class Potato
            include RSpock
          end
        HEREDOC

        expected = <<~HEREDOC
          class Potato
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
