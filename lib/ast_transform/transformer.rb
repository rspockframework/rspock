# frozen_string_literal: true
require 'parser/current'
require 'unparser'
require 'ast_transform/source_map'

module ASTTransform
  class Transformer
    # Constructs a new Transformer instance.
    #
    # @param transformations [Array<ASTTransform::AbstractTransformation>] The transformations to be run.
    def initialize(*transformations)
      @transformations = transformations
    end

    # Builds the AST for the given +source+.
    #
    # @param source [String] The input source code.
    # @param file_path [String] The file_path. This is important for source mapping in backtraces.
    #
    # @return [Parser::AST::Node] The AST.
    def build_ast(source, file_path: 'tmp')
      buffer = create_buffer(source, file_path)
      parser.parse(buffer)
    end

    # Builds the AST for the given +file_path+.
    #
    # @param file_path [String] The input file path.
    #
    # @return [Parser::AST::Node] The AST.
    def build_ast_from_file(file_path)
      source = File.read(file_path)
      build_ast(source, file_path: file_path)
    end

    # Transforms the given +source+.
    #
    # @param source [String] The input source code to be transformed.
    #
    # @return [String] The transformed code.
    def transform(source)
      ast = build_ast(source)
      transformed_ast = transform_ast(ast)
      Unparser.unparse(transformed_ast)
    end

    # Transforms the give +file_path+.
    #
    # @param file_path [String] The input file to be transformed. This is required for source mapping in backtraces.
    # @param transformed_file_path [String] The file path to the transformed file.
    #
    # @return [String] The transformed code.
    def transform_file(file_path, transformed_file_path)
      source = File.read(file_path)
      transform_file_source(source, file_path, transformed_file_path)
    end

    # Transforms the given +source+ in +file_path+.
    #
    # @param source [String] The input source code to be transformed.
    # @param file_path [String] The file path for the input +source+. This is required for source mapping in backtraces.
    # @param transformed_file_path [String] The file path to the transformed filed. This is required to register the
    # SourceMap.
    #
    # @return [String] The transformed code.
    def transform_file_source(source, file_path, transformed_file_path)
      source_ast = build_ast(source, file_path: file_path)
      # At this point, the transformed_ast contains line number mappings for the original +source+.
      transformed_ast = transform_ast(source_ast)

      transformed_source = Unparser.unparse(transformed_ast)

      register_source_map(file_path, transformed_file_path, transformed_ast, transformed_source)

      transformed_source
    end

    # Transforms the given +ast+.
    #
    # @param ast [Parser::AST::Node] The input AST to be transformed.
    #
    # @return [Parser::AST::Node] The transformed AST.
    def transform_ast(ast)
      @transformations.inject(ast) do |ast, transformation|
        transformation.run(ast)
      end
    end

    private

    def create_buffer(source, file_path)
      buffer = Parser::Source::Buffer.new(file_path)
      buffer.source = source.dup.force_encoding(parser.default_encoding)

      buffer
    end

    def parser
      @parser&.reset
      @parser ||= Parser::CurrentRuby.new
    end

    def register_source_map(source_file_path, transformed_file_path, transformed_ast, transformed_source)
      # The transformed_source is re-parsed to get the correct line numbers for the transformed_ast, which is the code
      # that will run.
      rewritten_ast = build_ast(transformed_source)
      source_map = ASTTransform::SourceMap.new(source_file_path, transformed_file_path, transformed_ast, rewritten_ast)
      ASTTransform::SourceMap.register_source_map(source_map)
    end
  end
end
