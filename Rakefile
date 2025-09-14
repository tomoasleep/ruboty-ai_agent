# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'steep/rake_task'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-rake'
end

Steep::RakeTask.new do |t|
  t.check.severity_level = :error
  t.watch.verbose
end

task default: %i[rubocop steep spec]
task autocorrect: %i[rubocop:autocorrect rbs steep spec]

namespace :rbs do
  desc 'Clean generated RBS files'
  task :clean do
    sh('rm -rf sig/generate')
    sh('rm -rf sig/generated-by-scripts')
  end

  desc 'Install rbs collection'
  task :collection do
    sh('bundle exec rbs collection install')
  end

  desc 'Run rbs-inline to generate RBS files'
  task :inline do
    sh('script/clean-orphaned-rbs.rb')
    sh('bundle exec rbs-inline --opt-out --output lib')
  end

  desc 'Generate RBS definitions by script/generate-rbs.rb'
  task :script do
    sh('script/generate-data-rbs.rb')
    sh('script/generate-concern-rbs.rb')
    sh('script/generate-memorized-ivar-rbs.rb')
  end
end

task rbs: %i[rbs:inline rbs:script]
