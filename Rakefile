require "bundler/gem_tasks"
require "rake/testtask"
require_relative "./lib/pixiurge/version"

Rake::TestTask.new("test:server") do |t|
  t.libs << "test/server"
  t.libs << "lib"
  t.test_files = FileList['test/server/**/*_test.rb']
end

file "releases/pixiurge-combined.js" => Rake::FileList["pixiurge/*.coffee", "vendor/*.js"] do
  sh "npm install" unless File.exist?("node_modules")
  sh "./node_modules/.bin/webpack --config pixiurge/webpack.config.js"
end

desc "Package the current Pixiurge Javascript into a combined archive."
task "js:dist" => "releases/pixiurge-combined.js" do
  sh "cp releases/pixiurge-combined.js releases/pixiurge-v#{Pixiurge::VERSION}pre.js"
  sh "cp releases/pixiurge-combined.js.map releases/pixiurge-v#{Pixiurge::VERSION}pre.js.map"
  #sh "cp releases/pixiurge-combined.min.js releases/pixiurge-v#{Pixiurge::VERSION}pre.min.js"
  #sh "cp releases/pixiurge-combined.min.js.map releases/pixiurge-v#{Pixiurge::VERSION}pre.min.js.map"
end

desc "Test the Javascript and Coffeescript libraries"
task "test:js" do
  sh "npm install" unless File.exist?("node_modules")
  sh "./test/js/bundle_and_test.sh"
end

desc "Run all tests, client and server"
task "test:all" => [ "test:server", "test:js" ]

#task :default => :test
