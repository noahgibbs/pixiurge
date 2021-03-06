require_relative "test_helper"

# This is, among other things, an example of how to set up both Rack
# and Websocket testing. They're set up completely separate and
# independent from each other.

class AuthTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage
  attr_reader :on_login_called
  attr_reader :on_player_login_called
  attr_reader :on_close_called
  attr_reader :on_player_logout_called

  def initialize(options = {})
    @mem_storage = Pixiurge::Authentication::MemStorage.new
    super(options.merge({ :storage => @mem_storage }))
  end

  def on_login(ws, username)
    super
    @on_login_called = true
  end

  def on_player_login(username)
    @on_player_login_called = true
  end

  def on_close(ws, code, reason)
    super
    @on_close_called = true
  end

  def on_player_logout(username)
    @on_player_logout_called = true
  end
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

  def test_get_failed_salt
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_GET_SALT, { "username" => "bobo" } ])
    ws.close

    assert_equal [ MultiJson.dump([ Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as \"bobo\"!" } ]) ], ws.sent_data
  end

  def test_bad_username
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT, { "username" => "bob ", "salt" => "", "bcrypted" => "" } ])
    ws.close

    assert_equal 1, ws.sent_data.length
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, ws.parsed_sent_data[0][0]
    assert ws.parsed_sent_data[0][1]["message"]["contains illegal"]
  end

  def test_fresh_registration_and_login
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT, { "username" => "bob", "salt" => "fake_salt", "bcrypted" => "fake_hash" } ])
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_GET_SALT, { "username" => "bob" } ])
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
    ws.close

    assert_equal 3, ws.sent_data.length
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_REGISTRATION, ws.parsed_sent_data[0][0]
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_SALT, ws.parsed_sent_data[1][0]
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_LOGIN, ws.parsed_sent_data[2][0]
  end

  def test_repeat_registration
    pixi_app = get_pixi_app
    pixi_app.mem_storage.account_state["existing"] = { "account" => { "username" => "existing", "salt" => "fake_salt", "hashed" => "fake_hash" } }

    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT, { "username" => "existing", "salt" => "fake_salt2", "bcrypted" => "fake_hash2" } ])
    ws.close

    assert_equal 1, ws.sent_data.length
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, ws.parsed_sent_data[0][0]
  end

  def test_existing_login
    pixi_app = get_pixi_app
    pixi_app.mem_storage.account_state["existing"] = { "account" => { "username" => "existing", "salt" => "fake_salt", "hashed" => "fake_hash" } }

    ws.open
    # Before first message, make sure on_login and on_player_login weren't called
    assert !pixi_app.on_login_called, "Shouldn't receive on_login handler call before first message"
    assert !pixi_app.on_player_login_called, "Shouldn't receive on_player_login handler call before first message"
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "existing", "bcrypted" => "fake_hash" } ])
    assert_equal 1, ws.sent_data.length
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_LOGIN, ws.parsed_sent_data[0][0]
    # Now make sure on_login and on_player_login handlers got called
    assert pixi_app.on_login_called, "Received on_login handler call"
    assert pixi_app.on_player_login_called, "Received on_player_login handler call"
    assert !pixi_app.on_close_called, "Shouldn't receive on_close handler call before socket close"
    assert !pixi_app.on_player_logout_called, "Shouldn't receive on_player_logout handler call before logout"

    ws.close
    assert pixi_app.on_close_called, "Received on_close handler call"
    assert pixi_app.on_player_logout_called, "Received on_player_logout handler call"

  end
end
