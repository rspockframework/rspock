# frozen_string_literal: true
require 'test_helper'
require 'tmpdir'
require 'open3'
require 'rspock/declarative'

module RSpock
  # End-to-end pin for backtrace source mapping: a failing RSpock test run in a
  # subprocess must report line numbers from the file the developer wrote, not
  # from the transformed code that actually executes.
  #
  # The filter-disabled variant documents that the Minitest plugin
  # (lib/minitest/rspock_plugin.rb) is what delivers the mapping — ast-transform
  # alone makes the *paths* correct but leaves *line numbers* transformed. If
  # that test starts failing, the plugin may genuinely be redundant.
  class BacktraceSourceMappingTest < ::Minitest::Test
    extend RSpock::Declarative

    # Blank lines and multi-line expressions make source line numbers diverge
    # from transformed ones, so a wrong mapping cannot pass by coincidence.
    FIXTURE_SOURCE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class SourceMappingFixtureTest < Minitest::Test
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

    # Ruby subprocesses inherit bundler state pointing at rspock's Gemfile;
    # scrub it so the child resolves gems from the parent's live load paths.
    # MT_NO_PLUGINS: minitest's gem-scanning plugin discovery can activate a
    # second minitest version (the Ruby default gem) over the -I one, breaking
    # the run; the runner requires the rspock plugin explicitly instead.
    CLEAN_ENV = {
      "RUBYOPT" => nil,
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_BIN_PATH" => nil,
      "MT_NO_PLUGINS" => "1",
    }.freeze

    test "failure messages and backtraces cite source line numbers" do
      output = run_fixture_in_subprocess

      assertion_line = line_number_of(FIXTURE_SOURCE, "doubled == 999")
      raise_line = line_number_of(FIXTURE_SOURCE, "raise ArgumentError")

      assert_includes output, "[test/source_mapping_fixture_test.rb:#{assertion_line}]",
        "assertion failure should cite the source line of the failed expectation\n#{output}"
      assert_includes output, "test/source_mapping_fixture_test.rb:#{raise_line}:in",
        "error backtrace should cite the source line of the raise\n#{output}"
      assert_includes output, "2 failures", output
    end

    test "without the plugin filter, line numbers are transformed — the plugin is still needed" do
      with_filter = run_fixture_in_subprocess
      without_filter = run_fixture_in_subprocess(disable_plugin_filter: true)

      refute_equal cited_line_numbers(with_filter), cited_line_numbers(without_filter),
        "disabling the plugin filter no longer changes reported line numbers; " \
          "the Minitest plugin may have become redundant\nwith: #{with_filter}\nwithout: #{without_filter}"
    end

    private

    def run_fixture_in_subprocess(disable_plugin_filter: false)
      Dir.mktmpdir do |tmpdir|
        dir = File.realpath(tmpdir)
        FileUtils.mkdir_p(File.join(dir, "test"))
        File.write(File.join(dir, "test", "source_mapping_fixture_test.rb"), FIXTURE_SOURCE)
        File.write(File.join(dir, "runner.rb"), runner_source(disable_plugin_filter))

        output, status = Open3.capture2e(CLEAN_ENV, RbConfig.ruby, *load_path_flags, "runner.rb", chdir: dir)
        refute status.success?, "fixture run should fail (it contains failing tests)\n#{output}"

        output
      end
    end

    # Plugin discovery is off (MT_NO_PLUGINS), so the enabled variant applies
    # the plugin's init by hand — the same call minitest would make; the
    # disabled variant simply leaves minitest's default filter in place.
    def runner_source(disable_plugin_filter)
      install_plugin_filter = <<~RUBY
        require "minitest/rspock_plugin"
        Minitest.plugin_rspock_init({})
      RUBY

      <<~RUBY
        require "ast_transform"
        ASTTransform.install
        require "minitest/autorun"
        require "rspock"
        #{disable_plugin_filter ? "" : install_plugin_filter}
        require_relative "test/source_mapping_fixture_test"
      RUBY
    end

    # The child needs the same rspock and dependency load paths as this
    # process, without going through bundler.
    def load_path_flags
      $LOAD_PATH.grep(%r{/(lib|gems)(/|\z)}).flat_map { |path| ["-I", path] }
    end

    def cited_line_numbers(output)
      output.scan(%r{test/source_mapping_fixture_test\.rb:(\d+)}).flatten.map(&:to_i).sort.uniq
    end

    def line_number_of(source, snippet)
      index = source.lines.index { |line| line.include?(snippet) }
      flunk "snippet not found in source: #{snippet}" if index.nil?
      index + 1
    end
  end
end
