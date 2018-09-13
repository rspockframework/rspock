# frozen_string_literal: true
require 'ast_transform/transformation_helper'

module ASTTransform
  class AbstractTransformation < Parser::AST::Processor
    include TransformationHelper

    # Runs this transformation on +node+.
    # Note: If you want to add one-time checks to the transformation, override this, then call super.
    #
    # @param node [Parser::AST::Node] The node to be transformed.
    #
    # @return [Parser::AST::Node] The transformed node.
    def run(node)
      process(node)
    end

    # Used internally by Parser::AST::Processor to process each node. DO NOT OVERRIDE.
    def process(node)
      return node unless node.is_a?(Parser::AST::Node)

      process_node(node)
    end

    private

    # Processes the given +node+.
    # Note: If you want to do processing on each node, override this.
    #
    # @param node [Parser::AST::Node] The node to be transformed.
    #
    # @return [Parser::AST::Node] The transformed node.
    def process_node(node)
      method(:process).super_method.call(node)
    end
  end
end
