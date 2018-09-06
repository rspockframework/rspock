# frozen_string_literal: true
require 'minitest/reporters'
require 'ast_transform/source_map'

module Minitest
  module Reporters
    class RakeRerunReporter < Minitest::Reporters::ProgressReporter

      def initialize(options = {})
        @rerun_user_prefix = options.fetch(:rerun_prefix, "")
        super
      end

      def record(test)
        super
        return unless test.failure

        puts
        puts
        puts yellow("You can rerun failed/error test by commands (you can add rerun prefix with 'rerun_prefix' option):")
        print_rerun_command(test)
        puts
      end

      private

      def print_rerun_command(test)
        message = rerun_message_for(test)
        unless message.nil? || message.strip == ''
          puts
          puts yellow(message)
        end
      end

      def rerun_message_for(test)
        file_path = location(test.failure).gsub(/(\:\d*)\z/, "")
        file_path = ASTTransform::SourceMap.for_file_path(file_path)&.source_file_path || file_path
        "Rerun:\n#{@rerun_user_prefix} rake test TEST=#{file_path} TESTOPTS=\"--name=#{test.name} -v\""
      end

      def location(exception)
        last_before_assertion = ''

        exception.backtrace.reverse_each do |ss|
          break if ss =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
          last_before_assertion = ss
          break if ss =~ /_test.rb\:/
        end

        last_before_assertion.sub(/:in .*$/, '')
      end
    end
  end
end
