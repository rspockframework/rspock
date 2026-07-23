# frozen_string_literal: true

# Toolchain-only manifest for d3mlabs' dev tool: it provisions this exact
# Ruby (rbenv + shadowenv) for `dev` commands. Gems stay bundler-managed
# through the hand-written gemspec/Gemfile; contributors without dev can
# ignore this file and use .ruby-version.
require "dev/deps"

Dev::Deps.define do
  ruby "4.0.6"
end
