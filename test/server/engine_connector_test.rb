require_relative "test_helper"

require "demiurge"

class EngineConnectorTestApp < Pixiurge::AuthenticatedApp
  attr_reader :mem_storage

  def initialize(engine, options = {})
    @engine = engine

    # For this test, use memory-only storage with an accessor so we can mess with it.
    @mem_storage = Pixiurge::Authentication::MemStorage.new
    super(options.merge({ :storage => @mem_storage }))

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
  location "somewhere else" do
    display { invisible }
  end
  agent "player template" do
    display do
      # Bob and Sam can be invisible, while Murray and Phil are visible
      if item.name.size < 4
        invisible
      else
        particle_source({ "shape" => "square" })
      end
    end
  end
end
DSL

  # Set up the Pixiurge App for Websocket-based testing
  def pixi_app(engine, options = {})
    EngineConnectorTestApp.new engine, options
  end

  def setup
    super  # Destroy @pixi_app and @ws

    # Now destroy the connector and engine (see #connector)
    @pixi_connector = nil
    @demi_engine = nil
  end

  def connector
    return @pixi_connector if @pixi_connector

    # Load TMX files with the test data dir as a root; this also clears the TMX cache
    Demiurge::Tmx::TmxLocation.default_cache.root_dir = File.join(__dir__, "data")
    @demi_engine = Demiurge::DSL.engine_from_dsl_text(["EngineConnectorDSL", ENGINE_DSL])

    pixi_app = get_pixi_app(@demi_engine)  # Initialize @pixi_app and mock websocket
    pixi_app.mem_storage.account_state.merge!(
      { "bob" => { "account" => { "username" => "bob", "salt" => "fake_salt", "hashed" => "fake_hash" } },
        "sam" => { "account" => { "username" => "sam", "salt" => "fake_salt2", "hashed" => "fake_hash2" } },
        "murray" => { "account" => { "username" => "murray", "salt" => "fake_salt3", "hashed" => "fake_hash3" } },
        "phil" => { "account" => { "username" => "phil", "salt" => "fake_salt4", "hashed" => "fake_hash4" } } })

    @pixi_connector = Pixiurge::EngineConnector.new pixi_app, :engine => @demi_engine
  end

  def test_basic_connector_creation
    con = connector
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal 4, ws.sent_data.size

    ws.close
  end

  def test_no_multiple_login_with_same_account
    socket_closed = false

    con = connector
    ws.open
    ws.on(:close) { socket_closed = true }
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal 4, ws.sent_data.size
    ws.clear_sent_data

    # Now, create another login from bob
    next_ws = additional_websocket
    next_ws.open
    next_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "bob", "bcrypted" => "fake_hash" } ])
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

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
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "bob" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal 4, ws.sent_data.size
    ws.clear_sent_data

    # Now, create another login from sam
    next_ws = additional_websocket
    next_ws.on(:close) { socket_closed = true }
    next_ws.open
    next_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "sam", "bcrypted" => "fake_hash2" } ])
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

    # We should see login messages and no closing of either socket
    messages = next_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "sam" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal 4, next_ws.sent_data.size  # This would be higher if either of these players had visible bodies - they can't see each other

    assert_equal false, socket_closed
  end

  def test_multiple_login_mutual_visibility
    socket_closed = false

    con = connector

    # We'll use the first websocket for murray's connection
    ws.open
    ws.on(:close) { socket_closed = true }
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "murray", "bcrypted" => "fake_hash3" } ])

    # Now create another login from sam, who is invisible
    sam_ws = additional_websocket
    sam_ws.on(:close) { socket_closed = true }
    sam_ws.open
    sam_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "sam", "bcrypted" => "fake_hash2" } ])

    # Now create another login from phil
    phil_ws = additional_websocket
    phil_ws.on(:close) { socket_closed = true }
    phil_ws.open
    phil_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "phil", "bcrypted" => "fake_hash4" } ])

    # Make sure all the login and NewItem notifications have gone through
    @demi_engine.flush_notifications

    # Check murray's messages
    messages = ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "murray" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[4]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[5]
    assert_equal 6, ws.sent_data.size

    # Check sam's messages
    messages = sam_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "sam" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[4]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[5]
    assert_equal 6, ws.sent_data.size

    # Check phil's messages
    messages = phil_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "phil" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[4]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[5]

    # Nobody should have the socket closed on them
    assert_equal false, socket_closed
  end

  def test_reconnection_messages
    con = connector

    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "murray", "bcrypted" => "fake_hash3" } ])
    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications
    ws.close

    new_ws = additional_websocket
    new_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "murray", "bcrypted" => "fake_hash3" } ])
    @demi_engine.flush_notifications

    messages = new_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => "murray" } ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_INIT, { "width" => 640, "height" => 480, "ms_per_tick" => 300 } ], messages[1]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[2]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ], messages[3]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[4]
    assert_equal 5, messages.size
  end

  def test_same_location_movement_visibility
    con = connector

    # Connect websockets for murray, sam and phil
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "murray", "bcrypted" => "fake_hash3" } ])
    murray_ws = ws
    sam_ws = additional_websocket
    sam_ws.open
    sam_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "sam", "bcrypted" => "fake_hash2" } ])
    phil_ws = additional_websocket
    phil_ws.open
    phil_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "phil", "bcrypted" => "fake_hash4" } ])

    # The login doesn't really happen until the notification goes through...
    @demi_engine.flush_notifications

    demi_phil = @demi_engine.item_by_name("phil")
    demi_murray = @demi_engine.item_by_name("murray")
    demi_sam = @demi_engine.item_by_name("sam")

    demi_phil.move_to_position("right here#2,2")
    demi_murray.move_to_position("somewhere else")
    demi_sam.move_to_position("right here#5,5")
    @demi_engine.flush_notifications

    # Clear all the login and movement messages
    murray_ws.sent_data.clear
    sam_ws.sent_data.clear
    phil_ws.sent_data.clear

    # Advancing the simulation also flushes notifications
    @demi_engine.advance_one_tick

    assert_equal [], murray_ws.sent_data
    assert_equal [], sam_ws.sent_data
    assert_equal [], phil_ws.sent_data

    demi_phil = @demi_engine.item_by_name("phil")
    demi_phil.move_to_position("right here#2,3")
    @demi_engine.flush_notifications

    # Phil and sam should see phil move. But murray shouldn't - he's
    # in a different room.  Phil's display should pan to match his
    # position, though.
    assert_equal [], murray_ws.sent_data
    assert_equal [[Pixiurge::Protocol::Outgoing::DISPLAY_MOVE_DISPLAYABLE, "phil", { "old_position" => "right here#2,2", "position" => "right here#2,3", "options" => {}}]], sam_ws.parsed_sent_data
    assert_equal [[Pixiurge::Protocol::Outgoing::DISPLAY_MOVE_DISPLAYABLE, "phil", { "old_position" => "right here#2,2", "position" => "right here#2,3", "options" => {}}],
                  [Pixiurge::Protocol::Outgoing::DISPLAY_PAN_TO_PIXEL, 64, 96, {}]], phil_ws.parsed_sent_data
  end

  def test_cross_location_movement_visibility
    con = connector

    # Connect websockets for murray, sam and phil
    ws.open
    ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "murray", "bcrypted" => "fake_hash3" } ])
    murray_ws = ws
    sam_ws = additional_websocket
    sam_ws.open
    sam_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "sam", "bcrypted" => "fake_hash2" } ])
    phil_ws = additional_websocket
    phil_ws.open
    phil_ws.json_message([Pixiurge::Protocol::Incoming::AUTH_LOGIN, { "username" => "phil", "bcrypted" => "fake_hash4" } ])

    @demi_engine.flush_notifications

    # Clear all the login messages
    murray_ws.sent_data.clear
    sam_ws.sent_data.clear
    phil_ws.sent_data.clear

    # Advancing the simulation also flushes notifications
    @demi_engine.advance_one_tick

    assert_equal [], murray_ws.sent_data
    assert_equal [], sam_ws.sent_data
    assert_equal [], phil_ws.sent_data

    demi_phil = @demi_engine.item_by_name("phil")
    demi_phil.move_to_position("somewhere else")
    @demi_engine.flush_notifications

    # Both murray and sam should see phil leave
    messages = murray_ws.parsed_sent_data
    assert_equal 1, murray_ws.sent_data.size
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "phil" ], messages[0]
    murray_ws.sent_data.clear
    messages = sam_ws.parsed_sent_data
    assert_equal 1, sam_ws.sent_data.size
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "phil" ], messages[0]
    sam_ws.sent_data.clear

    # Phil should see himself and murray (but not the invisible sam)
    # get hidden individually and a hide-all, then showing himself
    # Note that his new room is invisible and doesn't get shown.
    messages = phil_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>1, "location_block_height"=>1, "position"=>"somewhere else"}, "params" => { "shape" => "square" } } ], messages[1]
    assert_equal 2, messages.size
    phil_ws.sent_data.clear

    demi_phil.move_to_position("right here")
    @demi_engine.flush_notifications

    # And now phil should see himself hidden (not the room, it's
    # invisible), and then everybody shown, including himself and the
    # new room.
    messages = phil_ws.parsed_sent_data
    #assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "phil" ], messages[0]
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[0]

    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ]), "Phil should see himself shown when entering the room"
    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ]), "Phil should see murray shown when entering the room"
    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ]), "Phil should see the room shown when entering the room"

    assert_equal 4, messages.size
    phil_ws.sent_data.clear

    # The other two just see Phil enter
    messages = murray_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[0]
    assert_equal 1, murray_ws.sent_data.size
    murray_ws.sent_data.clear
    messages = sam_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ], messages[0]
    assert_equal 1, sam_ws.sent_data.size
    sam_ws.sent_data.clear

    # This should only send messages for sam - his Displayable is an Invisible
    demi_sam = @demi_engine.item_by_name("sam")
    demi_sam.move_to_position("somewhere else")
    @demi_engine.flush_notifications

    # So these two see nothing
    assert_equal [], murray_ws.sent_data
    assert_equal [], phil_ws.sent_data

    # Sam sees the old room disappear... But the new room doesn't appear, it's invisible.
    messages = sam_ws.parsed_sent_data
    #assert messages[0..2].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "phil" ]), "Phil should see phil hidden when leaving the room"
    #assert messages[0..2].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "murray" ]), "Phil should see murray hidden when leaving the room"
    #assert messages[0..2].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, "right here" ]), "Phil should see the room hidden when leaving the room"
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[0]
    sam_ws.sent_data.clear

    demi_sam.move_to_position("right here")
    @demi_engine.flush_notifications

    # They still see nothing
    assert_equal [], murray_ws.sent_data
    assert_equal [], phil_ws.sent_data

    # Sam sees the new room appear, including murray and phil
    messages = sam_ws.parsed_sent_data
    assert_equal [ Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL ], messages[0]
    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "phil", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ]), "Phil should see himself shown when entering the room"
    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "murray", { "type" => "particle_source", "displayable"=>{"x"=>nil, "y"=>nil, "location_block_width"=>32, "location_block_height"=>32, "position"=>"right here"}, "params" => { "shape" => "square" } } ]), "Phil should see murray shown when entering the room"
    assert messages[1..3].include?([ Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, "right here", { "type" => "tmx", "url" => "/tmx/magecity_cc0_lorestrome.json" } ]), "Phil should see the room shown when entering the room"
    assert_equal 4, sam_ws.sent_data.size
  end
end
