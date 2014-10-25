require "bundler/gem_tasks"
require 'rspec/core/rake_task'

# Default directory to look in is `/specs`
# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'documentation']
end

RSpec::Core::RakeTask.new(:sublime) do |task|
  ENV['RUBYOPT'] = "-W0"
  task.rspec_opts = ['--no-color']
end

task :default => :spec

