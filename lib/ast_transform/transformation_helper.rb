# frozen_string_literal: true
require 'parser'

module ASTTransform
  module TransformationHelper
    def self.included(base)
      base.extend(Methods)
      base.include(Methods)
    end

    module Methods
      def s(type, *children, **properties)
        Parser::AST::Node.new(type, children, properties)
      end
    end
  end
end
