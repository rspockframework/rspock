# frozen_string_literal: true
module ASTTransform
  module InstructionSequence
    class << self
      def using_bootsnap_compilation?
        filepath, = RubyVM::InstructionSequence.method(:load_iseq).source_location
        filepath =~ %r{/bootsnap/}
      rescue NameError
        false
      end

      def source_to_transformed_iseq(source, source_path)
        transformer = ASTTransform::Transformer.new(ASTTransform::Transformation.new)
        rewritten_file_pathname = write_pathname(source_path)

        rewritten_source = transformer.transform_file_source(source, source_path, rewritten_file_pathname.to_s)
        write(rewritten_source, rewritten_file_pathname)

        RubyVM::InstructionSequence.compile(rewritten_source, rewritten_file_pathname.to_s, rewritten_file_pathname.to_s)
      end

      def write_pathname(file_path)
        project_path = File.expand_path("")
        relative_source_file_pathname = Pathname.new(file_path).relative_path_from(Pathname.new(project_path))
        Pathname.new("").join(project_path, 'tmp', 'rspock', relative_source_file_pathname)
      end

      def write(string, pathname)
        FileUtils.mkdir_p(pathname.dirname)
        File.open(pathname, 'w') do |file|
          file.write(string)
        end
      end
    end
  end
end
