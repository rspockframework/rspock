# frozen_string_literal: true
require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.start do
  add_filter('/test/')
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
  ])
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rspock"

# Pry + Byebug
# NOTE: Must be loaded before ASTTransform.install, otherwise we get a bunch of require_relative errors.
# pry-byebug must be required explicitly — pry discovers plugins lazily on the first binding.pry,
# but by then ASTTransform.install has hooked into require and interferes with plugin loading.
require "pry"
require "pry-byebug"

ASTTransform.install
