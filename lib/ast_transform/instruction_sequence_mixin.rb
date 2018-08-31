# frozen_string_literal: true
require 'pathname'
require 'ast_transform/transformer'
require 'ast_transform/transformation'

module ASTTransform
  module InstructionSequenceMixin
    def load_iseq(source_path)
      begin
        contents = File.read(source_path)
        if source_path != __FILE__ && contents =~ /transform!/
          transformer = ASTTransform::Transformer.new(ASTTransform::Transformation.new)

          project_path = File.expand_path("")
          relative_source_file_pathname = Pathname.new(source_path).relative_path_from(Pathname.new(project_path))
          rewritten_file_pathname = Pathname.new("").join(project_path, 'tmp', 'rspock', relative_source_file_pathname)

          rewritten_source = transformer.transform_file(source_path, rewritten_file_pathname.to_s)

          FileUtils.mkdir_p(rewritten_file_pathname.dirname)
          File.open(rewritten_file_pathname, 'w') do |file|
            file.write(rewritten_source)
          end

          contents = rewritten_source
        end

        RubyVM::InstructionSequence.compile(contents, source_path)
      rescue SyntaxError, RuntimeError
        nil
      end
    end
  end
end
