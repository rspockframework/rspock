# frozen_string_literal: true
require 'pathname'
require 'test_helper'
require 'transformation_helper'
require 'ast_transform/abstract_transformation'
require 'ast_transform/transformer'

module ASTTransform
  class TransformerTest < Minitest::Test
    extend RSpock::Declarative
    include RSpock::Helpers::TransformationHelper

    class MethodCallToFooTransformation < ASTTransform::AbstractTransformation
      private

      def process_node(node)
        return unless node.type == :send
        node.updated(:send, [nil, :foo])
      end
    end

    class FooToBarTransformation < ASTTransform::AbstractTransformation
      private

      def process_node(node)
        return unless node.type == :send && node.children == [nil, :foo]
        node.updated(:send, [nil, :bar])
      end
    end

    class BarToFooBarTransformation < ASTTransform::AbstractTransformation
      private

      def process_node(node)
        return unless node.type == :send && node.children == [nil, :bar]
        node.updated(:send, [nil, :foo_bar])
      end
    end

    def setup
      @transformer = ASTTransform::Transformer.new
      @multi_transformer = ASTTransform::Transformer.new(
        MethodCallToFooTransformation.new, FooToBarTransformation.new, BarToFooBarTransformation.new
      )

      @source = <<~CODE
        method_call
      CODE

      @source_ast = s(:send, nil, :method_call)
    end

    test "#build_ast returns the expected AST" do
      ast = @transformer.build_ast(@source)
      assert_equal @source_ast, ast
    end

    test "#build_ast_from_file returns the expected AST" do
      pathname = Pathname.new('').join('tmp', 'test', 'ast_transform', 'transformer_test.rb')

      FileUtils.mkdir_p(pathname.dirname)
      File.open(pathname, 'w') do |file|
        file.write(@source)
      end

      ast = @transformer.build_ast_from_file(pathname.to_s)

      assert_equal @source_ast, ast
    ensure
      File.delete(pathname.to_s) if File.exists?(pathname.to_s)
    end

    test "#transform with no transformation" do
      assert_equal strip_end_line(@source), @transformer.transform(@source)
    end

    test "#transform with multiple transformations" do
      assert_equal 'foo_bar', @multi_transformer.transform(@source)
    end

    test "#transform_file returns the expected transformed code" do
      pathname = Pathname.new('').join('tmp', 'test', 'ast_transform', 'transformer_test.rb')
      transformed_pathname = Pathname.new('').join('tmp', 'test', 'ast_transform', 'transformed_transformer_test.rb')

      FileUtils.mkdir_p(pathname.dirname)
      File.open(pathname, 'w') do |file|
        file.write(@source)
      end

      transformed_source = @multi_transformer.transform_file(pathname.to_s, transformed_pathname.to_s)

      assert_equal 'foo_bar', transformed_source
    ensure
      File.delete(pathname.to_s) if File.exists?(pathname.to_s)
    end

    test "#transform_file_source returns the expected transformed code" do
      pathname = Pathname.new('').join('tmp', 'test', 'ast_transform', 'transformer_test.rb')
      transformed_pathname = Pathname.new('').join('tmp', 'test', 'ast_transform', 'transformed_transformer_test.rb')

      FileUtils.mkdir_p(pathname.dirname)
      File.open(pathname, 'w') do |file|
        file.write(@source)
      end

      transformed_source = @multi_transformer.transform_file_source(@source, pathname.to_s, transformed_pathname.to_s)

      assert_equal 'foo_bar', transformed_source
    ensure
      File.delete(pathname.to_s) if File.exists?(pathname.to_s)
    end

    test "#transform_ast with no transformation" do
      assert_same @source_ast, @transformer.transform_ast(@source_ast)
    end

    test "#transform_ast with multiple transformations" do
      expected_ast = s(:send, nil, :foo_bar)

      assert_equal expected_ast, @multi_transformer.transform_ast(@source_ast)
    end
  end
end
