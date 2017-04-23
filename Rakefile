require 'bundler/gem_tasks'
require 'rake/testtask'
require_relative './lib/grut'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :test_db_setup => ['grut:remove', 'grut:install']
task :default => [:test_db_setup, :test]
