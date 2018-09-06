# frozen_string_literal: true
require 'rspock/backtrace_filter'

module RSpock
  module Minitest
    class BacktraceFilter
      def initialize
        @backtrace_filter = RSpock::BacktraceFilter.new
      end

      def filter(backtrace)
        backtrace.map { |line| @backtrace_filter.filter_string(line) }
      end
    end
  end
end
