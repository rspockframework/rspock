# frozen_string_literal: true
require 'rspock/minitest/backtrace_filter'

module Minitest
  def self.plugin_rspock_init(_options)
    unless defined?(Rails)
      Minitest.backtrace_filter = RSpock::Minitest::BacktraceFilter.new
    end
  end
end
