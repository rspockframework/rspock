# frozen_string_literal: true
# TODO: This is implementation details
require 'ast_transform/instruction_sequence_mixin'

module ASTTransform
  class << self
    def install
      @installed ||= begin
        class << RubyVM::InstructionSequence
          prepend ::ASTTransform::InstructionSequenceMixin
        end
      end
    end
  end
end
