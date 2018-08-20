# frozen_string_literal: true
require 'parser/current'

module RSpock
  class SourceMap
    class << self
      def register_source_map(file_path, source_map)
        source_maps[file_path] = source_map
      end

      def for_file_path(file_path)
        source_maps[file_path]
      end

      private

      def source_maps
        @@source_maps ||= {}
      end
    end

    def initialize(source_file_path, source_ranges_ast, transformed_ranges_ast)
      @source_file_path = source_file_path
      @source_ranges_ast = source_ranges_ast
      @transformed_ranges_ast = transformed_ranges_ast

      @lines = Hash.new { |hash, key| hash[key] = [] }
      process_helper(@transformed_ranges_ast, [])
    end

    attr_reader :source_file_path

    def line(line_number)
      if @lines.key?(line_number)
        @lines[line_number].each do |dig_array|
          result = dig_node(@source_ranges_ast, dig_array)&.loc&.expression&.line
          return result if result
        end
      end

      nil
    end

    private

    def process_helper(node, idx)
      return false unless node&.is_a?(Parser::AST::Node)

      range = node&.loc&.expression
      return false unless range

      result = node.children.map.with_index do |child, index|
        process_helper(child, idx.dup << index)
      end.any?

      if range.line == range.last_line && !result
        @lines[range.line] << idx.dup
        result = true
      end

      result
    end

    def dig_node(node, indexes)
      return node if indexes.empty?

      result = dig(node, indexes)
      return result if result.is_a?(Parser::AST::Node)

      dig_node(node, indexes[0...-1])
    end

    def dig(node, indexes)
      indexes.inject(node) do |node, index|
        node.is_a?(Parser::AST::Node) ? node.children[index] : nil
      end
    end
  end
end
