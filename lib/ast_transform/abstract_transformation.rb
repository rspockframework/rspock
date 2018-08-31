# frozen_string_literal: true
require 'ast_transform/transformation_helper'

module ASTTransform
  class AbstractTransformation < Parser::AST::Processor
    include TransformationHelper

    def run(node)
      process(node)
    end

    def process(node)
      return node unless node.is_a?(Parser::AST::Node)

      super
    end
  end
end
