# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/test_method_def_transformation'

module RSpock
  module AST
    class TestMethodDefTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      def setup
        @transformation = RSpock::AST::TestMethodDefTransformation.new
      end

      test "#run does nothing if node is not a send test method call" do
        ast = s(:begin,
                s(:send, nil, :test,
                  s(:str, "Test Name")))

        actual = @transformation.run(ast)

        assert_same ast, actual
      end

      test "#run transforms str into dstr and injects test_index and line_number lvar" do
        ast = s(:send, nil, :test,
                s(:str, "Test Name"))

        actual = @transformation.run(ast)

        expected = s(:send, nil, :test,
                     s(:dstr,
                       s(:begin, s(:lvar, :test_index)),
                       s(:str, " line "),
                       s(:begin, s(:lvar, :line_number)),
                       s(:str, " "),
                       s(:str, "Test Name")))

        assert_equal expected, actual
      end

      test "#run injects test_index and line_number lvar into dstr" do
        ast = s(:send, nil, :test,
                s(:dstr,
                  s(:begin, s(:lvar, :a)),
                  s(:str, "Test Name")))

        actual = @transformation.run(ast)

        expected = s(:send, nil, :test,
                     s(:dstr,
                       s(:begin, s(:lvar, :test_index)),
                       s(:str, " line "),
                       s(:begin, s(:lvar, :line_number)),
                       s(:str, " "),
                       s(:begin, s(:lvar, :a)),
                       s(:str, "Test Name")))

        assert_equal expected, actual
      end
    end
  end
end
