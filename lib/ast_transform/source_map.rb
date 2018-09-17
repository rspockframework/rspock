# frozen_string_literal: true
require 'parser/current'

module ASTTransform
  class SourceMap
    class << self
      # Registers the given SourceMap.
      #
      # @param source_map [SourceMap] The source map to be registered.
      #
      # @return [void]
      def register_source_map(source_map)
        source_maps[source_map.transformed_file_path] = source_map

        nil
      end

      # Retrieves the SourceMap for the given +file_path+.
      #
      # @param file_path [String] The transformed file path.
      #
      # @return [SourceMap|nil] The associated source map.
      def for_file_path(file_path)
        source_maps[file_path]
      end

      private

      def source_maps
        @@source_maps ||= {}
      end
    end

    # Constructs a new SourceMap instance.
    #
    # Note: +source_ranges_ast+ and +transformed_ranges_ast+ must be equivalent ASTs.
    #
    # @param source_file_path [String] The path to the source file.
    # @param transformed_file_path [String] The path to the transformed file.
    # @param source_ranges_ast [Parser::AST::Node] A transformed AST that contains the source code ranges.
    # @param transformed_ranges_ast [Parser::AST::Node] A transformed AST that contains the ranges for the executed
    # code.
    def initialize(source_file_path, transformed_file_path, source_ranges_ast, transformed_ranges_ast)
      @source_file_path = source_file_path
      @transformed_file_path = transformed_file_path
      @source_ranges_ast = source_ranges_ast
      @transformed_ranges_ast = transformed_ranges_ast

      @lines = Hash.new { |hash, key| hash[key] = [] }
      extract_source_map_data(@transformed_ranges_ast, [])
      @source_map = build_source_map.freeze
    end

    attr_reader :source_file_path, :transformed_file_path, :source_map

    # Retrieves the mapped line number for the given +line_number+.
    #
    # @param line_number [Integer] The line number in the executed code to be mapped to the source.
    #
    # @return [Integer|nil] The mapped line number, otherwise nil if not found.
    def line(line_number)
      @source_map[line_number]
    end

    # Retrieves the line count for the executed code.
    #
    # @return [Integer] The line count.
    def line_count
      @transformed_ranges_ast&.loc&.expression.last_line || 0
    end

    private

    # Extracts SourceMap data from the given node.
    #
    # @param node [Parser::AST::Node] The node containing ranges for the executed code.
    #
    # @return [void]
    def extract_source_map_data(node, indexes)
      return false unless node&.is_a?(Parser::AST::Node)

      range = node.loc&.expression

      if range && range.line == range.last_line
        @lines[range.line] << indexes.dup
      end

      node.children.each.with_index do |child, index|
        extract_source_map_data(child, indexes.dup << index)
      end

      nil
    end

    # Builds the source map.
    #
    # @return [Hash] A Hash containing line numbers from executed code to source code.
    def build_source_map
      (1..line_count).each.with_object({}) {|it, hash| hash[it] = source_line(it) }
    end

    # Retrieves the source line for the given +line_number+ in the executed code.
    #
    # @param line_number [Integer] The line number in the executed code.
    #
    # @return [Integer|nil] The line number in the source code, or nil if cannot be mapped.
    def source_line(line_number)
      if @lines.key?(line_number)
        @lines[line_number].each do |dig_array|
          result = approximate_dig_last_valid_node(@source_ranges_ast, dig_array)&.loc&.expression&.line
          return result if result
        end
      end

      nil
    end

    # Recursively look for node represented by +indexes+ in +node+. If not found, goes back +depth+ nodes and search for
    # the node pointed to by +indexes+.
    #
    # @param node [Parser::AST::Node] The node to search into. This must be a node in the +@source_ranges_ast+.
    # @param indexes [Array<Integer>] Child indexes pointing to the node we're looking for in +node+.
    # @param depth [Integer] Number of nodes to go up to search for the node pointed to by +indexes+.
    #
    # @return [Parser::AST::Node|nil] The node found, nil otherwise.
    def approximate_dig_last_valid_node(node, indexes, depth = 1)
      return node if indexes.empty?

      result = dig_node(node, indexes)
      return result if result.is_a?(Parser::AST::Node) || depth <= 0

      queried_node = dig_last_valid_node(@transformed_ranges_ast, indexes)

      last_known_index = dig_last_valid_node_index(node, indexes[0...-depth])
      query_indexes = indexes[0...last_known_index]

      last_known_node = dig_node(node, query_indexes)

      search_node(last_known_node, queried_node)
    end

    # Recursively search the children of +node+ for an equivalent +queried_node+.
    #
    # @param node [Parser::AST::Node] The current node to search in.
    # @param queried_node [Parser::AST::Node] The equivalent node to search for.
    #
    # @return [Parser::AST::Node|nil] The found node from the +node+ graph, nil otherwise.
    def search_node(node, queried_node)
      return unless node&.is_a?(Parser::AST::Node)
      return node if node == queried_node

      node.children.each do |child_node|
        result = search_node(child_node, queried_node)
        return result if result
      end

      nil
    end

    # Finds the index for the last valid node represented by +indexes+ in the children of +node+.
    #
    # @param node [Parser::AST::Node] The current node to search in.
    # @param indexes [Array<Integer>] The array of indexes pointing to the child node to be retrieved from +node+.
    #
    # @return [Integer|nil] The index of the node if found, nil otherwise.
    def dig_last_valid_node_index(node, indexes)
      return if indexes.empty?

      result = dig_node(node, indexes)
      current_index = indexes&.size
      return current_index if result.is_a?(Parser::AST::Node)

      dig_last_valid_node_index(node, indexes[0...-1])
    end

    # Recursively look for the node represented by +indexes+ in the children of +node+. If not found, returns the last
    # valid node.
    #
    # @param node [Parser::AST::Node] The node to look into.
    # @param indexes [Array<Integer>] The array of indexes pointing to the child node to be retrieved from +node+.
    #
    # @return [Parser::AST::Node|nil] The node if found, nil otherwise.
    def dig_last_valid_node(node, indexes)
      return node if indexes.empty?

      result = dig_node(node, indexes)
      return result if result.is_a?(Parser::AST::Node)

      dig_last_valid_node(node, indexes[0...-1])
    end

    # Recursively look for the node represented by +indexes+ in the children of +node+.
    #
    # @param node [Parser::AST::Node] The node to look into.
    # @param indexes [Array<Integer>] The array of indexes pointing to the child node to be retrieved from +node+.
    #
    # @return [Parser::AST::Node|nil] The node if found, nil otherwise.
    def dig_node(node, indexes)
      indexes.inject(node) do |node, index|
        return nil unless node.is_a?(Parser::AST::Node)
        node.children[index]
      end
    end
  end
end
