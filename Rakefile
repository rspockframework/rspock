# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  # Ensure we load test_loader first for ASTTransform.install
  filepath = File.expand_path('test/test_loader.rb', __dir__)
  t.ruby_opts << "-r #{filepath}"
  t.warning = false

  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
