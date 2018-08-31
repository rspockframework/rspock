# frozen_string_literal: true
require 'parser/current'
require 'unparser'
require 'ast_transform/source_map'

module ASTTransform
  class Transformer
    def initialize(*transformations)
      @transformations = transformations
    end

    def transform(source)
      ast = build_ast(source)
      transformed_ast = run_transformations(ast)
      Unparser.unparse(transformed_ast)
    end

    def transform_file(file_path, transformed_file_path)
      source = File.read(file_path)
      source_ast = build_ast(source, file_path: file_path)
      # At this point, the transformed_ast contains line number mappings for the original +source+.
      transformed_ast = run_transformations(source_ast)

      transformed_source = Unparser.unparse(transformed_ast)

      register_source_map(file_path, transformed_file_path, transformed_ast, transformed_source)

      transformed_source
    end

    private

    def build_ast(source, transformation = nil, file_path: nil)
      buffer = create_buffer(source, file_path)
      ast = parser.parse(buffer)
      transformation&.run(ast) || ast
    end

    def create_buffer(source, file_path = nil)
      buffer = Parser::Source::Buffer.new(file_path || "tmp")
      buffer.source = source.dup.force_encoding(parser.default_encoding)

      buffer
    end

    def parser
      @parser&.reset
      @parser ||= Parser::CurrentRuby.new
    end

    def run_transformations(ast)
      @transformations.inject(ast) do |ast, transformation|
        transformation.run(ast)
      end
    end

    def register_source_map(source_file_path, transformed_file_path, transformed_ast, transformed_source)
      # The transformed_source is re-parsed to get the correct line numbers for the transformed_ast, which is the code
      # that will run.
      rewritten_ast = build_ast(transformed_source)
      source_map = ASTTransform::SourceMap.new(source_file_path, transformed_ast, rewritten_ast)
      ASTTransform::SourceMap.register_source_map(transformed_file_path, source_map)
    end
  end
end
