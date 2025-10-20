# frozen_string_literal: true

$:.unshift __dir__
require "bundler/gem_tasks"
require "rake/testtask"
require "yard"
require "standard/rake"

MODULES = %w[core mysql redis postgres nginx elasticsearch opensearch kafka mariadb mongo redpanda]

%w[test standard].each do |task_name|
  desc "Run #{task_name} task for all projects"
  task task_name do
    errors = []
    MODULES.each do |project|
      puts "Running #{task_name} for #{project}"
      system(%(cd #{project} && #{$0} #{task_name} --trace)) || errors << project
    end
    fail("Errors in #{errors.join(", ")}") unless errors.empty?
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["{#{MODULES.join(",")}}/lib/**/*.rb"]
  t.options = ["--protected", "--readme", "README.md", "--title", "Testcontainers for Ruby"]
end

task default: %i[test standard]
