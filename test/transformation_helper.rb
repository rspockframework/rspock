# frozen_string_literal: true
require 'rspock/ast/comparison_to_assertion_transformation'
require 'ast_transform/transformer'
require 'ast_transform/transformation_helper'
require 'string_helper'

module RSpock
  module Helpers
    module TransformationHelper
      include ASTTransform::TransformationHelper
      include RSpock::Helpers::StringHelper

      def transform(source, *transformations)
        ASTTransform::Transformer.new(*transformations).transform(source)
      end
    end
  end
end
