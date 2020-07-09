
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rspock/version"

Gem::Specification.new do |spec|
  spec.name          = "rspock"
  spec.version       = RSpock::VERSION
  spec.authors       = ["Jean-Philippe Duchesne"]
  spec.email         = ["jpduchesne89@gmail.com"]

  spec.summary       = 'Data-driven testing framework.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/jpduchesne/rspock'
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '~> 2.5'

  if ENV['TRAVIS']
    if ENV['TRAVIS_TAG'].nil? || ENV['TRAVIS_TAG'].empty?
      spec.version = "#{spec.version}-alpha-#{ENV['TRAVIS_BUILD_NUMBER']}"
    elsif ENV['TRAVIS_TAG'] != spec.version.to_s
      raise "Tag name (#{ENV['TRAVIS_TAG']}) and Gem version (#{spec.version}) are different"
    end
  end

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "minitest-reporters", "~> 1.4"
  spec.add_development_dependency "pry", "~> 0.13"
  spec.add_development_dependency "pry-byebug", "~> 3.9"
  spec.add_development_dependency "rake", "~> 13.0"

  # Runtime dependencies
  spec.add_runtime_dependency "ast_transform", "~> 1.0.0.pre.alpha.pre"
  spec.add_runtime_dependency "minitest", "~> 5.0"
  spec.add_runtime_dependency "mocha", "~> 1.0"
  spec.add_runtime_dependency "parser", "~> 2.5"
  spec.add_runtime_dependency "unparser", "~> 0.4"
end
