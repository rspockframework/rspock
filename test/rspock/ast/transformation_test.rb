# frozen_string_literal: true
require 'test_helper'
require 'string_helper'

module RSpock
  module AST
    class TransformationTest < Minitest::Test
      extend RSpock::Declarative
      include ASTTransform::TransformationHelper
      include RSpock::Helpers::StringHelper
      include RSpock::Helpers::TransformationHelper

      def setup
        @transformation = RSpock::AST::Transformation.new
      end

      test "empty test block raises" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            
          end
        HEREDOC

        error = assert_raises RSpock::AST::BlockError do
          transform(source)
        end

        assert_equal "Test method @ tmp:1:1 must start with one of these Blocks: #{[:Given, :When, :Expect]}", error.message
      end

      test "first node cannot be regular code" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            b = 2
          end
        HEREDOC

        error = assert_raises RSpock::AST::BlockError do
          transform(source)
        end

        assert_equal "Test method @ tmp:1:1 must start with one of these Blocks: #{[:Given, :When, :Expect]}", error.message
      end

      test "first node can be regular code if strict mode is disabled" do
        @transformation = RSpock::AST::Transformation.new(strict: false)

        source = <<~HEREDOC
          test "Adding 1 and 2 results in 3" do
            assert_equal 3, 1 + 2
          end
        HEREDOC

        expected = <<~HEREDOC
          test("Adding 1 and 2 results in 3") do
            assert_equal(3, 1 + 2)
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "first node cannot be a non-starting block" do
        source = <<~HEREDOC
          test "Adding \#{a} and \#{b} results in \#{c}" do
            Cleanup "cleanup stuff"
          end
        HEREDOC

        error = assert_raises RSpock::AST::BlockError do
          transform(source)
        end

        assert_equal "Test method @ tmp:1:1 must start with one of these Blocks: #{[:Given, :When, :Expect]}", error.message
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
          def initialize(node)
            super(:Start1, node)
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
          RSpock::AST::Transformation.new(start_block_class: start_block_class, source_map: source_map),
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
          def initialize(node)
            super(:Start1, node)
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

        error = assert_raises RSpock::AST::BlockError do
          transform(
            source,
            RSpock::AST::Transformation.new(start_block_class: start_block_class, source_map: source_map),
          )
        end

        assert_equal "Block Block1 @ tmp:2:3 must be followed by one of these Blocks: #{[:End]}", error.message
      end

      test "#run adds extend RSpock::Declarative when using Class.new" do
        source = <<~HEREDOC
          Potato = Class.new do
            
          end
        HEREDOC

        expected = <<~HEREDOC
          Potato = Class.new do
            begin
              extend(RSpock::Declarative)
            rescue StandardError => e
              ::RSpock::BacktraceFilter.new.filter_exception(e)
              raise
            end
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "#run adds extend RSpock::Declarative when using traditional class definition" do
        source = <<~HEREDOC
          class Potato
            
          end
        HEREDOC

        expected = <<~HEREDOC
          class Potato
            begin
              extend(RSpock::Declarative)
            rescue StandardError => e
              ::RSpock::BacktraceFilter.new.filter_exception(e)
              raise
            end
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "raises if block is followed by an illegal block when code is inside a Class" do
        source = <<~HEREDOC
          class Potato
            test "Adding \#{a} and \#{b} results in \#{c}" do
              Block1
              Block2
            end
          end
        HEREDOC

        start_block_class = Class.new(RSpock::AST::Block) do
          def initialize(node)
            super(:Start1, node)
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

        assert_raises RSpock::AST::BlockError do
          transform(
            source,
            RSpock::AST::Transformation.new(start_block_class: start_block_class, source_map: source_map),
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
          test(\"Adding 1 and 2 results in 3\") do
            actual = (1 + 2)
            assert_equal(3, actual)
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
          [[1, 2, 3, 10], [4, 5, 9, 11]].each.with_index do |(a, b, c, _line_number_), _test_index_|
            test(\"\#{\"Adding \"}\#{a}\#{\" and \"}\#{b}\#{\" results in \"}\#{c}\#{" "}\#{_test_index_}\#{" line "}\#{_line_number_}\") do
              actual = (a + b)
              assert_equal(c, actual)
            end
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "test with cleanup block" do
        source = <<~HEREDOC
          test "Adding 1 and 2 results in 3" do
            When "adding 1 and 2 together"
            actual = 1 + 2

            Then "we get the expected result"
            actual == 3

            Cleanup
            method1
            method2
          end
        HEREDOC

        expected = <<~HEREDOC
          test(\"Adding 1 and 2 results in 3\") do
            begin
              actual = (1 + 2)
              assert_equal(3, actual)
            ensure
              method1
              method2
            end
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "test with interactions" do
        source = <<~HEREDOC
          test "interactions" do
            Given
            dep = mock
            foo = Foo.new(dep)
        
            When
            foo.foo
        
            Then
            0 * dep.bar
            1 * dep.foo
          end
        HEREDOC

        expected = <<~HEREDOC
          test(\"interactions\") do
            dep = mock
            foo = Foo.new(dep)
            dep.expects(:bar).times(0)
            dep.expects(:foo).times(1)
            foo.foo
          end
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      private

      def transform(source, *transformations)
        transformations << @transformation if transformations.empty?
        super(source, *transformations)
      end
    end
  end
end
