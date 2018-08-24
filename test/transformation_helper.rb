# frozen_string_literal: true
require 'rspock/ast/comparison_to_assertion_transformation'
require 'rspock/transformer'

module RSpock
  module Helpers
    module TransformationHelper
      include RSpock::AST::TransformationHelper

      def transform(source, *transformations)
        Transformer.new(*transformations).transform(source)
      end

      def strip_end_line(str)
        str.gsub(/\n$/, '')
      end
    end
  end
end
