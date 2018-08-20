# frozen_string_literal: true
require 'rspock/ast/transformation_helper'

module RSpock
  module AST
    class AbstractTransformation < Parser::AST::Processor
      include TransformationHelper
    end
  end
end
