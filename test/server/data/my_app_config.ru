require "pixiurge/config_ru"

#file = File.new File.join(__dir__, "log", "http_req.txt"), "a"
#file.sync = true
#use Rack::CommonLogger, file

#EM.error_handler do |e|
#  STDERR.puts "ERROR: #{e.message}\n#{e.backtrace.join "\n"}\n"
#end

Pixiurge.rack_builder self
Pixiurge.root_dir __dir__
Pixiurge.coffeescript_dirs "coffee"
Pixiurge.static_dirs "static"
Pixiurge.static_files "bobo.txt"

run Pixiurge.handler
