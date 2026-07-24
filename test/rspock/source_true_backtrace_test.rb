# frozen_string_literal: true
require 'test_helper'
require 'tmpdir'
require 'open3'
require 'rspock/declarative'

module RSpock
  # End-to-end pin for source-true backtraces: a failing RSpock test run in a subprocess must report
  # line numbers from the file the developer wrote — with NO filtering machinery of any kind.
  # Line-aligned emission places each transformed statement on its source line, so the VM's raw line
  # numbers are already the source line numbers; there is no plugin, no BacktraceFilter, and no
  # SourceMap left to install.
  class SourceTrueBacktraceTest < ::Minitest::Test
    extend RSpock::Declarative

    # The blank lines and split expressions (`1 +` / `raise ArgumentError,`) are load-bearing: a
    # naive unparse would compress them, shifting every later statement's line number. Without them,
    # even a non-aligned emitter would happen to reproduce the source line numbers, and this test
    # would pass without proving alignment.
    FIXTURE_SOURCE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class BacktraceFixtureTest < Minitest::Test
        test "assertion failure" do
          Given "a value built across lines"
          value = 1 +
            1

          When "doubling it"
          doubled = value * 2

          Then "an expectation that cannot hold"
          doubled == 999
        end

        test "runtime error" do
          When "raising mid-stimulus"
          raise ArgumentError,
            "kaboom"

          Then "unreached"
          raises RuntimeError
        end
      end
    RUBY

    # Ruby subprocesses inherit bundler state pointing at rspock's Gemfile; scrub it so the child
    # resolves gems from the parent's live load paths. MT_NO_PLUGINS: minitest's gem-scanning plugin
    # discovery can activate a second minitest version (the Ruby default gem) over the -I one,
    # breaking the run. Nothing rspock-specific needs plugging in anymore.
    CLEAN_ENV = {
      "RUBYOPT" => nil,
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_BIN_PATH" => nil,
      "MT_NO_PLUGINS" => "1",
    }.freeze

    test "raw failure messages and backtraces cite source line numbers, with zero filter machinery" do
      output = run_fixture_in_subprocess

      assertion_line = line_number_of(FIXTURE_SOURCE, "doubled == 999")
      raise_line = line_number_of(FIXTURE_SOURCE, "raise ArgumentError")

      assert_includes output, "[test/backtrace_fixture_test.rb:#{assertion_line}]",
        "assertion failure should cite the source line of the failed expectation\n#{output}"
      assert_includes output, "test/backtrace_fixture_test.rb:#{raise_line}:in",
        "error backtrace should cite the source line of the raise\n#{output}"
      assert_includes output, "2 failures", output
    end

    private

    def run_fixture_in_subprocess
      Dir.mktmpdir do |tmpdir|
        dir = File.realpath(tmpdir)
        FileUtils.mkdir_p(File.join(dir, "test"))
        File.write(File.join(dir, "test", "backtrace_fixture_test.rb"), FIXTURE_SOURCE)
        File.write(File.join(dir, "runner.rb"), <<~RUBY)
          require "ast_transform"
          ASTTransform.install
          require "minitest/autorun"
          require "rspock"
          require_relative "test/backtrace_fixture_test"
        RUBY

        output, status = Open3.capture2e(CLEAN_ENV, RbConfig.ruby, *load_path_flags, "runner.rb", chdir: dir)
        refute status.success?, "fixture run should fail (it contains failing tests)\n#{output}"

        output
      end
    end

    # The child needs the same rspock and dependency load paths as this process, without going through bundler.
    def load_path_flags
      $LOAD_PATH.grep(%r{/(lib|gems)(/|\z)}).flat_map { |path| ["-I", path] }
    end

    def line_number_of(source, snippet)
      index = source.lines.index { |line| line.include?(snippet) }
      flunk "snippet not found in source: #{snippet}" if index.nil?
      index + 1
    end
  end
end
