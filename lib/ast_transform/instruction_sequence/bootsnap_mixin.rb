# frozen_string_literal: true

require 'ast_transform/transformer'
require 'ast_transform/instruction_sequence/mixin_utils'
require 'pathname'

module ASTTransform
  module InstructionSequence
    module BootsnapMixin
      def input_to_storage(source, source_path)
        return ASTTransform::MixinUtils.try_super(self, :input_to_storage, source, source_path) if source_path == __FILE__
        return ASTTransform::MixinUtils.try_super(self, :input_to_storage, source, source_path) unless source =~ /transform!/

        iseq = ASTTransform::InstructionSequence.source_to_transformed_iseq(source, source_path)
        iseq.to_binary
      rescue SyntaxError
        raise ::Bootsnap::CompileCache::Uncompilable, 'syntax error'
      end
    end
  end
end
