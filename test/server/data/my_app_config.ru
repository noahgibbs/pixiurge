require "pixiurge"

#file = File.new File.join(__dir__, "log", "http_req.txt"), "a"
#file.sync = true
#use Rack::CommonLogger, file

#EM.error_handler do |e|
#  STDERR.puts "ERROR: #{e.message}\n#{e.backtrace.join "\n"}\n"
#end

# Use a raw base-class app - we're not specializing the behavior in any way.
app = Pixiurge::App.new
app.rack_builder self
app.root_dir __dir__
app.coffeescript_dirs "coffee"
app.static_dirs "static"
app.static_files "bobo.txt"
app.tmx_dirs "tmx"

run app.handler
