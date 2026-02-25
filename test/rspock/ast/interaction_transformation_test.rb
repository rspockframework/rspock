# frozen_string_literal: true
require 'test_helper'
require 'string_helper'
require 'rspock/ast/interaction_transformation'
require 'transformation_helper'

module RSpock
  module AST
    class InteractionTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::StringHelper
      include RSpock::Helpers::TransformationHelper

      def setup
        @transformation = RSpock::AST::InteractionTransformation.new
      end

      test "message without params is transformed properly" do
        source = <<~HEREDOC
          1 * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).times(1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "message with params is transformed properly" do
        source = <<~HEREDOC
          1 * receiver.message(param1, *param2, p3: param3)
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).with(param1, *param2, p3: param3).times(1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "chained receiver is transformed properly" do
        source = <<~HEREDOC
          1 * base_object.receiver.message
        HEREDOC

        expected = <<~HEREDOC
          base_object.receiver.expects(:message).times(1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "any_matcher is transformed to at_least(0)" do
        source = <<~HEREDOC
          _ * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(0)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "irange with ints is transformed properly" do
        source = <<~HEREDOC
          (1..2) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1).at_most(2)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "irange with any_matcher as min is transformed properly" do
        source = <<~HEREDOC
          (_..2) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(0).at_most(2)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "irange with method call as min is transformed properly" do
        source = <<~HEREDOC
          (min_value..2) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(min_value).at_most(2)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "irange with any_matcher as max is transformed properly" do
        source = <<~HEREDOC
          (1.._) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "irange with method call as max is transformed properly" do
        source = <<~HEREDOC
          (1..max_value) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1).at_most(max_value)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "erange with ints is transformed properly" do
        source = <<~HEREDOC
          (1...3) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1).at_most(3 - 1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "erange with any_matcher as min is transformed properly" do
        source = <<~HEREDOC
          (_...3) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(0).at_most(3 - 1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "erange with method call as min is transformed properly" do
        source = <<~HEREDOC
          (min_value...3) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(min_value).at_most(3 - 1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "erange with any_matcher as max is transformed properly" do
        source = <<~HEREDOC
          (1..._) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "erange with method call as max is transformed properly" do
        source = <<~HEREDOC
          (1...max_value) * receiver.message
        HEREDOC

        expected = <<~HEREDOC
          receiver.expects(:message).at_least(1).at_most(max_value - 1)
        HEREDOC

        assert_equal strip_end_line(expected), transform(source)
      end

      test "lhs with multiple children raises" do
        source = <<~HEREDOC
          (1; 2) * receiver.message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:1/, e.message
      end

      test "irange with invalid node as min raises" do
        source = <<~HEREDOC
          ("abc"..2) * receiver.message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:2/, e.message
      end

      test "irange with invalid node as max raises" do
        source = <<~HEREDOC
          (1.."abc") * receiver.message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:5/, e.message
      end

      test "lhs with begin node and not a range raises" do
        source = <<~HEREDOC
          (1) * receiver.message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:1/, e.message
      end

      test "lhs with invalid node raises" do
        source = <<~HEREDOC
          "abc" * receiver.message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:1/, e.message
      end

      test "rhs with invalid node raises" do
        source = <<~HEREDOC
          1 * "abc"
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:5/, e.message
      end

      test "rhs without receiver raises" do
        source = <<~HEREDOC
          1 * message
        HEREDOC

        e = assert_raises RSpock::AST::InteractionTransformation::InteractionError do
          transform(source)
        end

        assert_match /tmp:1:5/, e.message
      end

      private

      def transform(source, *transformations)
        transformations << @transformation if transformations.empty?
        super(source, *transformations)
      end
    end
  end
end
