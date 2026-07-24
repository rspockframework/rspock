# frozen_string_literal: true
require 'test_helper'
require 'tmpdir'
require 'open3'
require 'rspock/declarative'

module RSpock
  # Acceptance tests for line-aligned emission through the full RSpock transformation: raw line numbers — no
  # Minitest plugin, no BacktraceFilter, no SourceMap — must already be source line numbers. When these are green,
  # the whole mapping apparatus is deletable.
  #
  # Counterpart of ast-transform's LineAlignmentTest; the fixtures exercise the RSpock dialect specifically
  # (Then assertions, Where tables, interactions, Cleanup).
  class LineAlignmentTest < ::Minitest::Test
    extend RSpock::Declarative

    # Same env scrubbing rationale as SourceTrueBacktraceTest: children inherit bundler state pointing at rspock's
    # Gemfile, and minitest's gem-scanning plugin discovery can activate a second minitest version.
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

    # The interaction argument expression `Integer("boom")` raises when the Mocha expectation setup executes —
    # pinning the line at which interaction setup runs. The setup must execute at the interaction's own source line
    # (the When body defers past it), not at the When position interactions used to hoist to.
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

    # When the Then block declares interactions, the When body is thunked past the Mocha setups — historically that
    # hid `result` (a local first assigned inside the thunk's closure is closure-local), so reading it in Then
    # raised NameError. The lowering now pre-declares thunked assignments at method scope; the expectation must
    # fail as a plain assertion failure that can SEE the value.
    WHEN_RESULT_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class WhenResultFixtureTest < Minitest::Test
        class Subject
          def initialize(dep)
            @dep = dep
          end

          def call
            @dep.ping(1)
            42
          end
        end

        test "When result stays readable when interactions defer the When body" do
          Given "a mocked collaborator"
          dep = mock
          subject = Subject.new(dep)

          When "exercising the subject"
          result = subject.call

          Then "the interaction and an expectation on the result that cannot hold"
          1 * dep.ping(1)
          result == 999
        end
      end
    RUBY

    test "a When-assigned local is readable in Then despite interaction deferral, raw" do
      output = run_fixture("when_result_fixture_test.rb", WHEN_RESULT_FIXTURE)
      assertion_line = line_number_of(WHEN_RESULT_FIXTURE, "result == 999")

      # A failure (not an error): a NameError on `result` would be an error.
      assert_includes output, "1 failures, 0 errors",
        "the result expectation should fail as an assertion, proving `result` was readable\n#{output}"
      assert_includes output, "42",
        "the failure message should show the deferred When's actual result\n#{output}"
      assert_includes output, "test/when_result_fixture_test.rb:#{assertion_line}",
        "the failing expectation should cite its source line\n#{output}"
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

    # The compound of the two hazards above: Cleanup runs inside ensure, so it observes the When local BOTH after
    # a failing Then AND with the When body deferred behind interaction setups. Historically this raised NameError
    # inside ensure, masking the real failure.
    CLEANUP_WHEN_LOCAL_FIXTURE = <<~RUBY
      transform!(RSpock::AST::Transformation)
      class CleanupWhenLocalFixtureTest < Minitest::Test
        class Subject
          def initialize(dep)
            @dep = dep
          end

          def call
            @dep.ping(1)
            :open
          end
        end

        test "Cleanup sees the When-assigned local" do
          Given "a mocked collaborator"
          dep = mock
          subject = Subject.new(dep)

          When "exercising the subject"
          handle = subject.call

          Then "an interaction and an expectation that cannot hold"
          1 * dep.ping(1)
          handle == :closed

          Cleanup "reporting what the ensure block can see"
          puts "cleanup saw \#{handle.inspect}"
        end
      end
    RUBY

    test "Cleanup reads a When-assigned local after a failing Then, raw" do
      output = run_fixture("cleanup_when_local_fixture_test.rb", CLEANUP_WHEN_LOCAL_FIXTURE)
      assertion_line = line_number_of(CLEANUP_WHEN_LOCAL_FIXTURE, "handle == :closed")

      assert_includes output, "cleanup saw :open",
        "the ensure-run Cleanup should see the When-assigned local\n#{output}"
      assert_includes output, "1 failures, 0 errors",
        "the Then failure should surface as an assertion failure, not be masked by a NameError in ensure\n#{output}"
      assert_includes output, "test/cleanup_when_local_fixture_test.rb:#{assertion_line}",
        "the failing expectation should cite its source line\n#{output}"
    end

    private

    # Runs +fixture_source+ in a subprocess with NO backtrace filtering of any kind: plugin discovery is off and
    # the rspock plugin is never installed. Whatever line numbers appear in the output are the VM's raw truth.
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
