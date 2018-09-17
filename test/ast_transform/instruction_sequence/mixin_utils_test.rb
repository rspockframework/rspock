# frozen_string_literal: true
require 'test_helper'
require 'ast_transform/instruction_sequence/mixin_utils'

module ASTTransform
  class MixinUtilsTest < Minitest::Test
    extend RSpock::Declarative

    class Base
      def foo
        'Base#foo'
      end
    end

    class FooBar < Base
      def foo
        'FooBar#foo'
      end

      def bar
        'FooBar#bar'
      end
    end

    test "#try_super when super method is defined" do
      foo_bar = FooBar.new

      assert_equal 'Base#foo', ASTTransform::MixinUtils.try_super(foo_bar, :foo)
    end

    test "#try_super when super method is not defined" do
      foo_bar = FooBar.new

      assert_nil ASTTransform::MixinUtils.try_super(foo_bar, :bar)
    end
  end
end
