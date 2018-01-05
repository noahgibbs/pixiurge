require "bundler/gem_tasks"
require "rake/testtask"
require_relative "./lib/pixiurge/version"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

file "releases/pixiurge-combined.min.js" => Rake::FileList["pixiurge/*.coffee", "vendor/*.js"] do
  sh "./node_modules/.bin/webpack --config pixiurge/webpack.config.js"
end

desc "Package the current Pixiurge Javascript into a combined, minified archive."
task :package_js => "releases/pixiurge-combined.min.js" do
  sh "cp releases/pixiurge-combined.js releases/pixiurge-v#{Pixiurge::VERSION}pre.js"
  sh "cp releases/pixiurge-combined.js.map releases/pixiurge-v#{Pixiurge::VERSION}pre.js.map"
  sh "cp releases/pixiurge-combined.min.js releases/pixiurge-v#{Pixiurge::VERSION}pre.min.js"
  sh "cp releases/pixiurge-combined.min.js.map releases/pixiurge-v#{Pixiurge::VERSION}pre.min.js.map"
end

task :default => :test
