require_relative "test_helper"

class PlayerApiTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage

  def initialize(options = {})
    @mem_storage = Pixiurge::Authentication::MemStorage.new
    super(options.merge({ "storage" => @mem_storage }))
  end

end

class PlayerApiTest < WebSocketTest
  # Set up the Pixiurge App for Websocket-based testing
  def pixi_app(options = {})
    PlayerApiTestApp.new options
  end

  def test_lowlevel_events
    pixi_app = get_pixi_app
    pixi_app.mem_storage.account_state["bob"] = { "account" => { "username" => "bob", "salt" => "fake_salt", "hashed" => "fake_hash" } }

    events = []
    [ "open", "login", "error", "close" ].each { |ev| pixi_app.on_event(ev) { events.push(ev) } }

    assert_equal [], events
    ws.open
    assert_equal [ "open" ], events
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
    assert_equal [ "open", "login" ], events
    ws.error("yup, a fake error")
    ws.close
    assert_equal [ "open", "login", "error", "close" ], events

    assert_equal 1, ws.sent_data.length
    assert_equal Pixiurge::Protocol::Outgoing::AUTH_LOGIN, ws.parsed_sent_data[0][0]
  end

end
