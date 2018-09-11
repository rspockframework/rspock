# frozen_string_literal: true
# TODO: This is implementation details
require 'ast_transform/instruction_sequence'
require 'ast_transform/instruction_sequence/mixin'
require 'ast_transform/instruction_sequence/bootsnap_mixin'

module ASTTransform
  class << self
    def install
      @installed ||= begin
        if defined?(Bootsnap) && ASTTransform::InstructionSequence.using_bootsnap_compilation?
          class << Bootsnap::CompileCache::ISeq
            prepend ::ASTTransform::InstructionSequence::BootsnapMixin
          end
        else
          class << RubyVM::InstructionSequence
            prepend ::ASTTransform::InstructionSequence::Mixin
          end
        end
      end
    end
  end
end
