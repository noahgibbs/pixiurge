require_relative "test_helper"

require "demiurge"

class EngineConnectorTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage

  def initialize(options = {})
    @mem_storage = Pixiurge::Authentication::MemStorage.new
    super(options.merge({ "storage" => @mem_storage }))

    on_event("player_message") do |username, action_name, *args|
    end

    on_event("player_login") do |username|
      body = @engine.item_by_name(username)
      if body
        raise("You can't create a body with reserved name #{username}!") unless body.state["player_body"] == username
      else
        player_template = @engine.item_by_name("player template")
        body = @engine.instantiate_new_item(username, player_template, "position" => "right here")
        body.state["$player_body"] = username
        body.run_action("create") if body.get_action("create")
      end
      body.run_action("login") if body.get_action("login")
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
  location "right here" do
  end
end
DSL

  # Set up the Pixiurge App for Websocket-based testing
  def pixi_app(options = {})
    EngineConnectorTestApp.new options
  end

  def connector
    return @pixi_connector if @pixi_connector
    pixi_app = get_pixi_app
    pixi_app.mem_storage.account_state["bob"] = { "account" => { "username" => "bob", "salt" => "fake_salt", "hashed" => "fake_hash" } }

    demi_engine = Demiurge::DSL.engine_from_dsl_text(["EngineConnectorDSL", ENGINE_DSL])

    @pixi_connector = Pixiurge::EngineConnector.new demi_engine, pixi_app
    @pixi_connector
  end

  def test_basic_connector_creation
    con = connector
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
