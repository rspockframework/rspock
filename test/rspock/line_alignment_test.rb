# frozen_string_literal: true
require 'test_helper'
require 'tmpdir'
require 'open3'
require 'rspock/declarative'

module RSpock
  # Acceptance tests for line-aligned emission through the full RSpock
  # transformation: raw line numbers — no Minitest plugin, no BacktraceFilter,
  # no SourceMap — must already be source line numbers. When these are green,
  # the whole mapping apparatus is deletable.
  #
  # Counterpart of ast-transform's LineAlignmentTest; the fixtures exercise
  # the RSpock dialect specifically (Then assertions, Where tables,
  # interactions, Cleanup).
  class LineAlignmentTest < ::Minitest::Test
    extend RSpock::Declarative

    # Same env scrubbing rationale as BacktraceSourceMappingTest: children
    # inherit bundler state pointing at rspock's Gemfile, and minitest's
    # gem-scanning plugin discovery can activate a second minitest version.
    CLEAN_ENV = {
      "RUBYOPT" => nil,
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_BIN_PATH" => nil,
      "MT_NO_PLUGINS" => "1",
    }.freeze

    THEN_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class ThenFixtureTest < Minitest::Test
        test "assertion failure cites its own line" do
          Given "a value built across lines"
          value = 1 +
            1

          When "doubling it"
          doubled = value * 2

          Then "an expectation that cannot hold"
          doubled == 999
        end
      end
    RUBY

    test "Then assertion failure cites the statement's source line, raw" do
      output = run_fixture("then_fixture_test.rb", THEN_FIXTURE)
      assertion_line = line_number_of(THEN_FIXTURE, "doubled == 999")

      assert_includes output, "test/then_fixture_test.rb:#{assertion_line}",
        "raw failure output should cite the assertion's source line\n#{output}"
    end

    WHERE_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class WhereFixtureTest < Minitest::Test
        test "row \#{a} plus \#{b} makes \#{c}" do
          When "adding a and b"
          actual = a + b

          Then "matching the expected column"
          actual == c

          Where
          a | b | c
          1 | 2 | 3
          4 | 5 | 999
        end
      end
    RUBY

    test "failing Where row cites the failing statement's source line, raw" do
      output = run_fixture("where_fixture_test.rb", WHERE_FIXTURE)
      assertion_line = line_number_of(WHERE_FIXTURE, "actual == c")

      assert_includes output, "test/where_fixture_test.rb:#{assertion_line}",
        "raw failure output should cite the Then statement's source line\n#{output}"
      assert_includes output, "1 failures", output
    end

    test "generated test name embeds the failing row's source line" do
      output = run_fixture("where_fixture_test.rb", WHERE_FIXTURE)
      failing_row_line = line_number_of(WHERE_FIXTURE, "4 | 5 | 999")

      # Minitest sanitizes test names, turning "line 13" into "line_13".
      assert_includes output, "line_#{failing_row_line}",
        "the failing test's name should embed the data row's source line " \
          "(the row-isolation selector target)\n#{output}"
    end

    # The interaction argument expression `Integer("boom")` raises when the
    # Mocha expectation setup executes — pinning the line at which interaction
    # setup runs. Today interactions are hoisted textually to the When
    # position, so the raw line is a transformed one; aligned emission must
    # keep the interaction's own source line while deferring the When body.
    INTERACTION_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class InteractionFixtureTest < Minitest::Test
        class Subject
          def initialize(dep)
            @dep = dep
          end

          def call
            @dep.ping(1)
          end
        end

        test "interaction setup executes at its own source line" do
          Given "a mocked collaborator"
          dep = mock
          subject = Subject.new(dep)

          When "exercising the subject"
          subject.call

          Then "the collaborator was pinged"
          1 * dep.ping(Integer("boom"))
        end
      end
    RUBY

    test "interaction setup execution is observed at the interaction's own source line, raw" do
      output = run_fixture("interaction_fixture_test.rb", INTERACTION_FIXTURE)
      interaction_line = line_number_of(INTERACTION_FIXTURE, "1 * dep.ping")

      assert_includes output, "test/interaction_fixture_test.rb:#{interaction_line}:in",
        "the raise from the interaction's argument expression should cite " \
          "the interaction's source line\n#{output}"
    end

    CLEANUP_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class CleanupFixtureTest < Minitest::Test
        test "cleanup failure cites its own line" do
          Given "a resource"
          resource = Object.new

          Expect "a passing expectation"
          resource.frozen? == false

          Cleanup "raising during teardown"
          raise "cleanup boom"
        end
      end
    RUBY

    test "Cleanup-block failure cites the cleanup statement's source line, raw" do
      output = run_fixture("cleanup_fixture_test.rb", CLEANUP_FIXTURE)
      cleanup_raise_line = line_number_of(CLEANUP_FIXTURE, 'raise "cleanup boom"')

      assert_includes output, "test/cleanup_fixture_test.rb:#{cleanup_raise_line}",
        "the cleanup raise should cite its source line\n#{output}"
    end

    private

    # Runs +fixture_source+ in a subprocess with NO backtrace filtering of any
    # kind: plugin discovery is off and the rspock plugin is never installed.
    # Whatever line numbers appear in the output are the VM's raw truth.
    def run_fixture(file_name, fixture_source)
      Dir.mktmpdir do |tmpdir|
        dir = File.realpath(tmpdir)
        FileUtils.mkdir_p(File.join(dir, "test"))
        File.write(File.join(dir, "test", file_name), fixture_source)
        File.write(File.join(dir, "runner.rb"), <<~RUBY)
          require "ast_transform"
          ASTTransform.install
          require "minitest/autorun"
          require "mocha/minitest"
          require "rspock"
          require_relative "test/#{file_name.delete_suffix('.rb')}"
        RUBY

        output, status = Open3.capture2e(CLEAN_ENV, RbConfig.ruby, *load_path_flags, "runner.rb", chdir: dir)
        refute status.success?, "fixture run should fail (it contains a failing test)\n#{output}"

        output
      end
    end

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
