# frozen_string_literal: true
module RSpock
  module Tasks
    class TruthTable
      # Constructs a new TruthTable.
      #
      # @param header [Array<String>] The column names, in a left to right order.
      # @param values_mapping [Hash<String, Array<String>>] A hash of the possible values with key being a column name
      # and value being an Array of possible values.
      def initialize(header, values_mapping)
        @header = header.dup.freeze
        @table_data = generate(@header.reverse, values_mapping, 0, []).freeze
      end

      attr_reader :header, :table_data

      # Retrieves the full table with header.
      #
      # @return [Array<Array<String>>] The table's lines.
      def table
        @table ||= begin
          data = table_data.empty? ? [] : table_data.dup
          data.unshift(header) unless header.empty?
          data
        end.freeze
      end

      alias_method :to_h, :table

      # Retrieves the table as a formatted string.
      #
      # @return [String] The formatted table.
      def to_s
        @to_s ||= format(to_h)
      end

      private

      def generate(header, values_mapping, index, lines)
        return lines if index == header.size

        duped_lines = lines.map(&:dup)

        return lines if values_mapping.empty?

        values_mapping[header[index]].each.with_index do |value, value_index|
          if duped_lines.empty?
            lines << [value]
          elsif value_index.zero?
            lines.each { |line| line.unshift(value) }
          else
            lines += duped_lines.map(&:dup)
            ((duped_lines.size * value_index)...lines.size).each do |i|
              lines[i].unshift(value)
            end
          end
        end

        generate(header, values_mapping, index + 1, lines)
      end

      def format(table)
        column_sizes = Hash.new { |hash, key| hash[key] = 0 }
        line_size = table.empty? ? 0 : table.first.size

        (0...line_size).each do |index|
          table.each do |line|
            column_size = column_sizes[index]
            line_column_size = line[index].to_s.size
            column_sizes[index] = line_column_size if line_column_size > column_size
          end
        end

        table.map do |line|
          line.map.with_index do |value, index|
            line.size - 1 == index ? value : Kernel.format("%-#{column_sizes[index]}s", value)
          end.join(' | ')
        end.join("\n")
      end
    end
  end
end
