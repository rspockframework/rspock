# frozen_string_literal: true
require 'ast_transform/abstract_transformation'

module RSpock
  module AST
    # dstr counterpart of TestMethodDefTransformation: appends the row index
    # and source line interpolations to an already-interpolated test name.
    class TestMethodDstrTransformation < ASTTransform::AbstractTransformation
      ROW_INDEX_AST = s(:begin, s(:lvar, :__rspock_row_index__))
      ROW_LINE_AST = s(:begin, s(:lvar, :__rspock_row_line__))

      SPACE_STR_AST = s(:str, " ")
      LINE_NUMBER_STR_AST = s(:str, " line ")

      def on_dstr(node)
        children = process_all(node).dup
        last = children.last

        if last&.type == :str
          children[-1] = s(:str, "#{last.children[0]} ")
        else
          children << SPACE_STR_AST
        end

        children.push(ROW_INDEX_AST, LINE_NUMBER_STR_AST, ROW_LINE_AST)
        node.updated(nil, children)
      end
    end
  end
end
