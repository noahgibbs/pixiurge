require_relative "test_helper"

require "demiurge"

class EngineConnectorTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage

  def initialize(engine, options = {})
    @engine = engine

    # For this test, use memory-only storage with an accessor so we can mess with it.
    @mem_storage = Pixiurge::Authentication::MemStorage.new
    super(options.merge({ "storage" => @mem_storage }))

    on_event("player_message") do |username, action_name, *args|
    end

    on_event("player_create_body") do |username|
      player_template = @engine.item_by_name("player template")
      body = @engine.instantiate_new_item(username, player_template, "position" => "right here")
    end

    on_event("player_logout") do |username|
      body = @engine.item_by_name(username)
      body.run_action("logout") if body && body.get_action("logout")
    end
  end

end

class EngineConnectorTest < WebSocketTest
  ENGINE_DSL = <<DSL
zone "Engine DSL Zone" do
  tmx_location "right here" do
    manasource_tile_layout "tmx/magecity_cc0_lorestrome.tmx"
  end
  agent "player template" do
    display { invisible }
  end
end
DSL

  # Set up the Pixiurge App for Websocket-based testing
  def pixi_app(engine, options = {})
    EngineConnectorTestApp.new engine, options
  end

  def connector
    return @pixi_connector if @pixi_connector

    # Load TMX files with the test data dir as a root; this also clears the TMX cache
    Demiurge::Tmx::TmxLocation.default_cache.root_dir = File.join(__dir__, "data")
    demi_engine = Demiurge::DSL.engine_from_dsl_text(["EngineConnectorDSL", ENGINE_DSL])

    pixi_app = get_pixi_app(demi_engine)  # Initialize @pixi_app and mock websocket
    pixi_app.mem_storage.account_state["bob"] = { "account" => { "username" => "bob", "salt" => "fake_salt", "hashed" => "fake_hash" } }
    pixi_app.mem_storage.account_state["sam"] = { "account" => { "username" => "sam", "salt" => "fake_salt2", "hashed" => "fake_hash2" } }

    @pixi_connector = Pixiurge::EngineConnector.new demi_engine, pixi_app
  end

  def test_basic_connector_creation
    con = connector
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_HIDE_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_TMX, "right here", "tmx/magecity_cc0_lorestrome.json" ], messages[3]
    assert_equal 4, ws.sent_data.size

    ws.close
  end

  def test_no_multiple_login_with_same_account
    socket_closed = false

    con = connector
    ws.open
    ws.on(:close) { socket_closed = true }
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_HIDE_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_TMX, "right here", "tmx/magecity_cc0_lorestrome.json" ], messages[3]
    assert_equal 4, ws.sent_data.size
    ws.clear_sent_data

    # Now, create another login from bob
    next_ws = additional_websocket
    next_ws.open
    next_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])

    # We should see a disconnect and a websocket close on the first socket
    assert_equal Pixiurge::Protocol::Outgoing::DISCONNECTION, ws.parsed_sent_data[0][0]
    assert socket_closed, "Pixiurge has closed the old socket after the new socket logged in with the same account"
  end

  def test_multiple_login_allowed_with_multiple_accounts
    socket_closed = false

    con = connector
    ws.open
    ws.on(:close) { socket_closed = true }
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_HIDE_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_TMX, "right here", "tmx/magecity_cc0_lorestrome.json" ], messages[3]
    assert_equal 4, ws.sent_data.size
    ws.clear_sent_data

    # Now, create another login from sam
    next_ws = additional_websocket
    next_ws.on(:close) { socket_closed = true }
    next_ws.open
    next_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "sam", "bcrypted" => "fake_hash2" } ])

    # We should see login messages and no closing of either socket
    messages = next_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "sam" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_HIDE_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_TMX, "right here", "tmx/magecity_cc0_lorestrome.json" ], messages[3]
    assert_equal 4, next_ws.sent_data.size

    assert_equal false, socket_closed
  end
end
