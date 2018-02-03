# Because this is an integration test in Pixiurge itself, use the local dev Pixiurge
$LOAD_PATH.unshift(__dir__ + "/../../../lib")

require "pixiurge/config_ru"

file = File.new File.join(__dir__, "log", "http_requests.txt"), "a"
file.sync = true
use Rack::CommonLogger, file

use Rack::ShowExceptions if ["development", ""].include?(ENV["RACK_ENV"].to_s)  # Useful for debugging, turn off in production

EM.error_handler do |e|
  STDERR.puts "ERROR: #{e.message}\n#{e.backtrace.join "\n"}\n"
end

require_relative "./hat_relay.rb"

app = HatRelay.new
app.rack_builder self
app.root_dir __dir__
app.root_redirect "/html/index.html"
#app.coffeescript_dirs "hat_relay"  # Optional for CoffeeScript front-end files
#app.static_dirs "tiles", "sprites", "vendor_js", "ui", "static"   # Optional for any static front-end files such as graphics, sounds, HTML or scripts
app.static_dirs "sprites"
app.static_files "index.html"  # Optional for individual static files
app.tmx_dirs "tmx"

app.tilt_dirs "html"

run app.handler
