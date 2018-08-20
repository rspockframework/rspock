# frozen_string_literal: true
require 'parser/current'
require 'rspock/ast/test_class_transformation'
require 'rspock/transformer'

module RSpock
  # This class is used to reload
  class Reloader
    def initialize(
      const,
      file_path,
      transformation: RSpock::AST::TestClassTransformation.new,
      transformer: Transformer.new(transformation)
    )
      @const = const
      @file_path = file_path
      @transformer = transformer
      @transformation = transformation
    end

    def perform
      remove_const
      # TODO: Either only transform portion of code under `@const` or extract it to eval only that part under `@const`, former sounds better
      # source = File.read(@file_path)

      project_path = File.expand_path("")
      relative_source_file_pathname = Pathname.new(@file_path).relative_path_from(Pathname.new(project_path))
      rewritten_file_pathname = Pathname.new("").join(project_path, 'tmp', 'rspock', relative_source_file_pathname)

      rewritten_source = @transformer.transform_file(@file_path, rewritten_file_pathname.to_s)

      FileUtils.mkdir_p(rewritten_file_pathname.dirname)
      File.open(rewritten_file_pathname, 'w') do |file|
        file.write(rewritten_source)
      end

      TOPLEVEL_BINDING.eval(rewritten_source, rewritten_file_pathname.to_s)
    end

    def remove_const
      name = const_name
      const_container.send(:remove_const, const_name) unless name.nil?
    end

    def const_name
      @const.name&.gsub(/^.*::/, '')
    end

    def const_container
      container_name = const_container_name
      container_name.empty? ? Object : Object.const_get(container_name)
    end

    def const_container_name
      @const.name.gsub(/(.*)(::)+?(.+)|(.*)/, '\1')
    end
  end
end
