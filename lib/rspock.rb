# frozen_string_literal: true
require 'rspock/version'

require 'rspock/declarative'
require 'parser/current'
require 'rspock/reloader'
require 'rspock/backtrace'

module RSpock
  def self.included(base)
    caller_file_path = caller_locations(1,1)[0].absolute_path

    # Unregisters the Runnable from Minitest
    base.runnables.pop

    RSpock::Reloader.new(base, caller_file_path).perform
  end
end
