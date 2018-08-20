$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rspock"

# Pry
require 'pry'

# Minitest
begin
  require "rubygems"
  gem "minitest"
rescue Gem::LoadError
  # do nothing
end

require "minitest"
require "minitest/spec"
require "minitest/mock"
require "minitest/hell" if ENV["MT_HELL"]

# Minitest Reporters
require "minitest/reporters"
Minitest::Reporters.use!([Minitest::Reporters::ProgressReporter.new])

Minitest.autorun
