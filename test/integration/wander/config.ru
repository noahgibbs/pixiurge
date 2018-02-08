require "pixiurge/config_ru"

file = File.new File.join(__dir__, "log", "http_requests.txt"), "a"
file.sync = true
use Rack::CommonLogger, file

use Rack::ShowExceptions if ["development", ""].include?(ENV["RACK_ENV"].to_s)  # Useful for debugging, turn off in production

EM.error_handler do |e|
  STDERR.puts "ERROR: #{e.message}\n#{e.backtrace.join "\n"}\n"
end

require_relative "./wander.rb"

app = Wander.new
app.rack_builder self
app.root_dir __dir__
app.root_redirect "/index.html"
#app.static_dirs "tiles", "sprites", "vendor_js", "ui", "static"   # Optional for any static front-end files such as graphics, sounds, HTML or scripts
app.static_files "index.html"  # Optional for individual static files

run app.handler
