# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'ast_transform/abstract_transformation'

module ASTTransform
  class AbstractTransformationTest < Minitest::Test
    extend RSpock::Declarative
    include RSpock::Helpers::TransformationHelper

    def setup
      @transformation = Class.new(ASTTransform::AbstractTransformation) do
        def on_send(node)
          node.updated(:lvar, [node.children[1]])
        end
      end.new

      @send_node = s(:send, nil, :a)
    end

    test "#run processes node if valid" do
      assert_equal s(:lvar, :a), @transformation.run(@send_node)
    end

    test "#run returns node if if invalid" do
      obj = Class.new
      assert_same obj, @transformation.run(obj)
    end

    test "#process processes node if valid" do
      assert_equal s(:lvar, :a), @transformation.process(@send_node)
    end

    test "#process returns node if invalid" do
      obj = Class.new
      assert_equal obj, @transformation.process(obj)
    end
  end
end
