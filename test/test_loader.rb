# frozen_string_literal: true
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)
SimpleCov.start do
  add_filter('/test/')
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rspock"

# Pry
# NOTE: Must be loaded before ASTTransform.install, otherwise we get a bunch of require_relative errors
require 'pry'

ASTTransform.install
