require_relative "test_helper"

require "demiurge"

class EngineConnectorTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage

  def initialize(engine, options = {})
    @engine = engine
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

    # Load our TMX files from the data subdir
    Dir.chdir(File.join(__dir__, "data")) do
      demi_engine = Demiurge::DSL.engine_from_dsl_text(["EngineConnectorDSL", ENGINE_DSL])
      pixi_app = get_pixi_app(demi_engine)  # Initialize @pixi_app and mock websocket
      pixi_app.mem_storage.account_state["bob"] = { "account" => { "username" => "bob", "salt" => "fake_salt", "hashed" => "fake_hash" } }

      @pixi_connector = Pixiurge::EngineConnector.new demi_engine, pixi_app
    end
    @pixi_connector
  end

  def test_basic_connector_creation
    con = connector
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])

    assert_equal 4, ws.sent_data.size
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], ws.parsed_sent_data[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "ms_per_tick" => 300 } ], ws.parsed_sent_data[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::LOAD_SPRITESHEET, "spritesheet_name" ], ws.parsed_sent_data[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::SHOW_SPRITESTACK, "spritestack_name", 0, 0 ], ws.parsed_sent_data[3]
    ws.sent_data.pop

    ws.close
  end

  #def test_lowlevel_events
  #  events = []
  #  [ "open", "login", "error", "close" ].each { |ev| pixi_app.on_event(ev) { events.push(ev) } }
  #
  #  assert_equal [], events
  #  ws.open
  #  assert_equal [ "open" ], events
  #  ws.json_message([Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE, Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
  #  assert_equal [ "open", "login" ], events
  #  ws.error("yup, a fake error")
  #  ws.close
  #  assert_equal [ "open", "login", "error", "close" ], events
  #
  #  assert_equal 1, ws.sent_data.length
  #  assert_equal Pixiurge::Protocol::Outgoing::AUTH_LOGIN, ws.parsed_sent_data[0][0]
  #end

end
