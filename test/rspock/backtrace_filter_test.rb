# frozen_string_literal: true
require 'test_helper'
require 'tmpdir'
require 'ast_transform/transformation'
require 'ast_transform/transformer'
require 'rspock/declarative'
require 'rspock/ast/transformation'
require 'rspock/backtrace_filter'

module RSpock
  # ::Minitest is explicit throughout: requiring rspock/minitest/backtrace_filter
  # defines RSpock::Minitest, which shadows the top-level constant inside this module.
  class BacktraceFilterTest < ::Minitest::Test
    extend RSpock::Declarative

    # Multi-line expressions collapse during unparse and the rescue wrapper
    # shifts the class body, so transformed line numbers differ from source
    # line numbers — making the mapping observable.
    FIXTURE_SOURCE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class BacktraceFilterFixture
        def kaboom
          value = 1 +
            2 +
            3
          raise ArgumentError,
            "kaboom-\#{value}"
        end
      end
    RUBY

    test "filter_string maps a transformed line number back to the source line" do
      with_registered_source_map do |source_path, _transformed_path, transformed_source|
        location = "#{source_path}:#{raise_line(transformed_source)}:in 'kaboom'"

        filtered = BacktraceFilter.new.filter_string(location)

        assert_equal "#{source_path}:#{raise_line(FIXTURE_SOURCE)}:in 'kaboom'", filtered
      end
    end

    test "filter_string maps a transformed file path back to the source file path" do
      with_registered_source_map do |source_path, transformed_path, transformed_source|
        location = "#{transformed_path}:#{raise_line(transformed_source)}:in 'kaboom'"

        filtered = BacktraceFilter.new.filter_string(location)

        assert_equal "#{source_path}:#{raise_line(FIXTURE_SOURCE)}:in 'kaboom'", filtered
      end
    end

    test "filter_string reports ? for an unmappable line number" do
      with_registered_source_map do |source_path, _transformed_path, _transformed_source|
        filtered = BacktraceFilter.new.filter_string("#{source_path}:99999:in 'kaboom'")

        assert_equal "#{source_path}:?:in 'kaboom'", filtered
      end
    end

    test "filter_string passes through locations without a registered source map" do
      location = "/nonexistent/other_file.rb:12:in 'foo'"

      assert_equal location, BacktraceFilter.new.filter_string(location)
    end

    test "filter_exception rewrites the exception backtrace to source locations" do
      with_registered_source_map do |source_path, transformed_path, _transformed_source|
        load transformed_path
        exception = assert_raises(ArgumentError) { BacktraceFilterFixture.new.kaboom }

        BacktraceFilter.new.filter_exception(exception)

        assert_equal "#{source_path}:#{raise_line(FIXTURE_SOURCE)}", exception.backtrace.first
      end
    end

    test "minitest filter maps mappable lines and passes through the rest" do
      # Required here, not at the top: loading this file defines RSpock::Minitest,
      # which would shadow ::Minitest for test files nested in module RSpock that
      # load after this one. In production the plugin loads at autorun time (after
      # all files), which is the timing this mirrors.
      require 'rspock/minitest/backtrace_filter'

      with_registered_source_map do |source_path, _transformed_path, transformed_source|
        backtrace = [
          "#{source_path}:#{raise_line(transformed_source)}:in 'kaboom'",
          "/nonexistent/other_file.rb:5:in 'x'",
        ]

        filtered = RSpock::Minitest::BacktraceFilter.new.filter(backtrace)

        assert_equal [
          "#{source_path}:#{raise_line(FIXTURE_SOURCE)}:in 'kaboom'",
          "/nonexistent/other_file.rb:5:in 'x'",
        ], filtered
      end
    end

    private

    # Transforms the fixture through the real pipeline, registering its
    # SourceMap, and writes both files to disk.
    def with_registered_source_map
      Dir.mktmpdir do |tmpdir|
        # Realpath matters: on macOS mktmpdir yields a /var symlink but
        # Thread::Backtrace::Location#absolute_path resolves to /private/var,
        # and SourceMap registration is keyed by exact path string.
        dir = File.realpath(tmpdir)
        source_path = File.join(dir, "backtrace_filter_fixture.rb")
        transformed_path = File.join(dir, "backtrace_filter_fixture_transformed.rb")
        File.write(source_path, FIXTURE_SOURCE)

        transformer = ASTTransform::Transformer.new(ASTTransform::Transformation.new)
        transformed_source = transformer.transform_file_source(FIXTURE_SOURCE, source_path, transformed_path)
        File.write(transformed_path, transformed_source)

        yield source_path, transformed_path, transformed_source
      end
    end

    def raise_line(source)
      line_number_of(source, "raise")
    end

    def line_number_of(source, snippet)
      index = source.lines.index { |line| line.include?(snippet) }
      flunk "snippet not found in source: #{snippet}" if index.nil?
      index + 1
    end
  end
end
