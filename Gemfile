source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Temporarily pin to the line-aligned-emission branch until ast_transform 3.0.0 ships.
gem "ast_transform", git: "https://github.com/rspockframework/ast-transform.git", branch: "jpd/line-aligned-emission"

# unparser 0.9 requires Ruby >= 3.3; we still test against 3.2.
gem "unparser", "< 0.9"

# Specify your gem's dependencies in rspock.gemspec
gemspec
