require_relative "test_helper"

# This is, among other things, an example of how to set up hybrid
# Rack/Websocket testing. They're basically just set up completely
# separate and independent from each other.

class AuthTestApp < Pixiurge::AuthenticatedApp
end

class AuthTest < WebSocketTest
  # We're doing Websockets on some tests and Rack on others - set up Rack too.
  include Rack::Test::Methods

  # This sets up a Rack::Builder app for Rack testing
  APP_TEXT = <<TEXT
require "pixiurge/config_ru"

# Why is this important? Because this sets nearly nothing except a
# Rack builder and a root dir, so we should make sure we can serve
# requests at all. For a more complex example that sets more asset
# directories, see the config.ru test.

# When would you use a real setup like this? Most obviously when you
# run a Ruby server that doesn't serve even the index.html and *only*
# acts as a Websocket server, which is totally fine. This
# will set up a non-Websocket server as well, but it will always
# return 404 for any file - no asset directories or files get set up,
# so none will be served.

app = AuthTestApp.new
app.rack_builder self
app.root_dir __dir__

run app.handler
TEXT
  # And here's the Rack::Builder app, which doesn't (in this case)
  # even get a reference to the corresponding Pixiurge app.
  def app
    @@my_app ||= Rack::Builder.parse_file(File.join(__dir__, "data", "my_app_config.ru")).first
  end

  # With Rack, make sure the server does the automatic serving of
  # Pixiurge itself, even with no asset directories configured.
  def test_can_serve_pixiurge_js_without_asset_dirs
    get '/pixiurge/pixiurge.js'
    assert last_response.ok?
    assert last_response.body["Pixiurge"]
  end

  # Now set up the Pixiurge App for Websocket-based testing
  def pixi_app(options = {})
    AuthTestApp.new options
  end

  def test_can_get_salt
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE, Pixiurge::Protocol::Incoming::AUTH_GET_SALT, { "username" => "bobo" } ])
    ws.close
  end
end
