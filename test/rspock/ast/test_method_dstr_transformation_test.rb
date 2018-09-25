# frozen_string_literal: true
require 'test_helper'
require 'rspock/ast/test_method_dstr_transformation'

module RSpock
  module AST
    class TestMethodDstrTransformationTest < Minitest::Test
      extend RSpock::Declarative
      include RSpock::Helpers::TransformationHelper

      def setup
        @transformation = RSpock::AST::TestMethodDstrTransformation.new
      end

      test "#run does nothing if node is not a send test method call" do
        ast = s(:begin,
                s(:send, nil, :test,
                  s(:str, "Test Name")))

        actual = @transformation.run(ast)

        assert_same ast, actual
      end

      test "#run returns same ast if there is no dstr" do
        ast = s(:send, nil, :test,
                s(:str, "Test Name"))

        actual = @transformation.run(ast)

        assert_same ast, actual
      end

      test "#run injects _test_index_ and _line_number_ lvar into dstr" do
        ast = s(:send, nil, :test,
                s(:dstr,
                  s(:begin, s(:lvar, :a)),
                  s(:str, "Test Name")))

        actual = @transformation.run(ast)

        expected = s(:send, nil, :test,
                     s(:dstr,
                       s(:begin, s(:lvar, :_test_index_)),
                       s(:str, " line "),
                       s(:begin, s(:lvar, :_line_number_)),
                       s(:str, " "),
                       s(:begin, s(:lvar, :a)),
                       s(:str, "Test Name")))

        assert_equal expected, actual
      end
    end
  end
end
