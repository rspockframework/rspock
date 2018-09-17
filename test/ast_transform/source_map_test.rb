# frozen_string_literal: true
require 'test_helper'
require 'transformation_helper'
require 'ast_transform/source_map'
require 'pathname'

module ASTTransform
  class SourceMapTest < Minitest::Test
    extend RSpock::Declarative
    include RSpock::Helpers::TransformationHelper

    def setup
      transformation = ASTTransform::Transformation.new
      @transformer = ASTTransform::Transformer.new(transformation)

      project_path = File.expand_path('')
      @example_rspock_test_pathname = Pathname.new(project_path).join('test', 'example_rspock_test.rb')
      source_ast = @transformer.build_ast_from_file(@example_rspock_test_pathname.to_s)
      transformed_ast_with_source_ranges = @transformer.transform_ast(source_ast)
      transformed_ast_transformed_ranges = @transformer.build_ast(Unparser.unparse(transformed_ast_with_source_ranges))

      @source_map = ASTTransform::SourceMap.new(
        @example_rspock_test_pathname.to_s,
        'tmp',
        transformed_ast_with_source_ranges,
        transformed_ast_transformed_ranges
      )
    end

    test "#source_map returns the expected Source Map" do
      assert_equal @source_map.source_map, SOURCE_MAP
      assert_equal true, @source_map.source_map.frozen?
    end

    test "#line returns the expected line number" do
      SOURCE_MAP.each do |key, val|
        msg = "Expected key #{key} to be equal to #{val}"

        if val.nil?
          assert_nil @source_map.line(key), msg
        else
          assert_equal val, @source_map.line(key), msg
        end
      end
    end

    test "#line_count returns expected value" do
      assert_equal 65, @source_map.line_count
    end

    test "#source_file_path returns the expected value" do
      assert_equal @example_rspock_test_pathname.to_s, @source_map.source_file_path
    end

    test "#transformed_file_path returns the expected value" do
      assert_equal 'tmp', @source_map.transformed_file_path
    end

    SOURCE_MAP = {
      1 => 2,
      2 => 5,
      3 => nil,
      4 => 6,
      5 => 7,
      6 => 8,
      7 => nil,
      8 => nil,
      9 => nil,
      10 => 21,
      11 => 12,
      12 => nil,
      13 => nil,
      14 => 14,
      15 => 17,
      16 => nil,
      17 => nil,
      18 => nil,
      19 => nil,
      20 => nil,
      21 => nil,
      22 => nil,
      23 => nil,
      24 => nil,
      25 => nil,
      26 => nil,
      27 => nil,
      28 => nil,
      29 => 31,
      30 => 25,
      31 => nil,
      32 => nil,
      33 => 27,
      34 => nil,
      35 => nil,
      36 => nil,
      37 => nil,
      38 => nil,
      39 => nil,
      40 => nil,
      41 => nil,
      42 => nil,
      43 => nil,
      44 => nil,
      45 => nil,
      46 => nil,
      47 => 44,
      48 => 35,
      49 => nil,
      50 => nil,
      51 => 37,
      52 => 40,
      53 => nil,
      54 => nil,
      55 => nil,
      56 => nil,
      57 => nil,
      58 => nil,
      59 => nil,
      60 => nil,
      61 => nil,
      62 => nil,
      63 => nil,
      64 => nil,
      65 => nil
    }
  end
end
