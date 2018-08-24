# frozen_string_literal: true
require 'rspock/ast/transformation_helper'

module RSpock
  module AST
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
end
