
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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"

  # Runtime dependencies
  spec.add_runtime_dependency "parser", "~> 2.5"
  spec.add_runtime_dependency "unparser", "~> 0.4"
  spec.add_runtime_dependency "ast_transform", "~> 0.1"
end
