# frozen_string_literal: true

require 'test_helper'
require 'string_helper'
require 'rspock/tasks/truth_table'

module RSpock
  class TruthTableTest < Minitest::Test
    extend RSpock::Declarative
    include RSpock::Helpers::StringHelper

    test "empty header and values_mapping results in an empty truth_table" do
      header = []
      values_mapping = {}

      truth_table = RSpock::Tasks::TruthTable.new(header, values_mapping)

      assert_empty truth_table.table_data
      assert_empty truth_table.header
      assert_equal [], truth_table.table
    end

    test "header and empty values_mapping results in a truth table with only a header line" do
      header = %w(a b c)
      values_mapping = {}

      truth_table = RSpock::Tasks::TruthTable.new(header, values_mapping)

      assert_empty truth_table.table_data
      assert_equal %w(a b c), truth_table.header
      assert_equal [%w(a b c)], truth_table.table
    end

    test "#table returns the expected table when header and values_mapping are present" do
      header = %w(a b c)
      values_mapping = {
        'a' => %w(0 1),
        'b' => %w(false true),
        'c' => %W('?')
      }

      truth_table = RSpock::Tasks::TruthTable.new(header, values_mapping)

      expected_table = [
        %w(a b c),
        %W(0 false '?'),
        %W(0 true '?'),
        %W(1 false '?'),
        %W(1 true '?'),
      ]

      assert_equal %w(a b c), truth_table.header
      assert_equal expected_table, truth_table.table
    end

    test "#to_s returns the expected table when header and values_mapping are present" do
      header = %w(a b c)
      values_mapping = {
        'a' => %w(0 1),
        'b' => %w(false true),
        'c' => %W('?')
      }

      truth_table = RSpock::Tasks::TruthTable.new(header, values_mapping)

      expected_table = <<~HEREDOC
        a | b     | c
        0 | false | '?'
        0 | true  | '?'
        1 | false | '?'
        1 | true  | '?'
      HEREDOC

      assert_equal %w(a b c), truth_table.header
      assert_equal strip_end_line(expected_table), truth_table.to_s
    end
  end
end
