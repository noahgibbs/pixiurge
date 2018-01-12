require "demiurge/tmx"
require "pixiurge/displayable"
#require "pixiurge/display_dsl"

# A single EngineConnector runs on the server, sending messages about
# the game world to the various player connections. An EngineConnector
# subscribes to events on a Demiurge engine for the gameworld and a
# Pixiurge App to connect to browsers.
#
# The EngineConnector acts, among other things, as a mapping between
# Demiurge objects, websockets, Player objects and Displayable
# objects.
#
# @since 0.1.0
class Pixiurge::EngineConnector
  attr_reader :engine

  # Constructor. Set up the EngineConnector as a gateway between the
  # demi_engine and the pixi_app.
  #
  # @param demi_engine [Demiurge::Engine] The Demiurge engine for world simulation
  # @param pixi_app [Pixiurge::App] The Pixiurge App for assets and network interactions
  # @since 0.1.0
  def initialize(demi_engine, pixi_app)
    @engine = demi_engine
    @app = pixi_app
    @players = {}      # Mapping of player name strings to Player objects (not Displayable objects or Demiurge items)
    @displayables = {} # Mapping of item names to Display objects such as Humanoids

    # First, subscribe to the engine and create local display copies of the various engine items.

    # Subscribing immediately avoids "oh, I missed that change" race
    # conditions with the engine spinning without the Engine Sync
    # realizing it. But it can cause "oh hey, I haven't seen that yet"
    # race conditions.
    @engine.subscribe_to_notifications(tracker: self.to_s) do |data|
      notified(data)
    end

    @engine.all_item_names.each do |item_name|
      item = @engine.item_by_name(item_name)
      register_engine_item(item)
    end

    # Next, subscribe to appropriate notifications for the Pixiurge
    # App - these let us handle player network connections.
    @app.on_event "player_login" do |username|
      demi_item = @engine.item_by_name(username)
      if demi_item
        raise("There is already a body with reserved name #{username} not marked for this player!") unless demi_item.state["$player_body"] == username
      else
        # No body yet? Send a signal to indicate that we need one.
        @app.send("send_event", "player_create_body", username)
        demi_item = @engine.item_by_name(username)
        unless demi_item
          STDERR.puts "No player body was created in Demiurge for #{username.inspect}! No login for you!"
          return
        end
        demi_item.state["$player_body"] = username
        demi_item.run_action("create") if demi_item.get_action("create")
        # Now register the player's body with the EngineConnector to make sure we have a Displayable for it
        register_engine_item(demi_item)
        displayable = @displayables[username]
        unless(displayable)
          raise "No displayable item was created for user #{username}'s body!"
        end
      end
      demi_item.run_action("login") if demi_item.get_action("login")
      ws = @app.websocket_for_username username
      displayable = @displayables[username]
      player = Pixiurge::Player.new websocket: ws, name: username, displayable: displayable
      add_player(player)
    end
    @app.on_event "player_logout" do |username|
      remove_player(@players[username]) if @players[username]
    end
    @app.on_event "player_reconnect" do |username|
    end
    @app.on_event "player_message" do |username, msg_type, *args|
    end
  end

  # Query for a Displayable object by Demiurge item name. This is
  # useful when trying to map a Demiurge location into a displayable
  # tilemapped area, for instance. It can also query for agents and
  # other non-location Demiurge items - anything with a Displayable
  # presence.
  #
  # @param item_name [String] The Demiurge item name to query
  # @return [Pixiurge::Displayable, nil] The Displayable equivalent item or nil if there isn't one.
  # @since 0.1.0
  def displayable_by_name(item_name)
    @displayables[item_name]
  end

  # Query for a Player object by account name, which should match the
  # Demiurge username for that player's body if there is one.
  #
  # @param username [String] The account name to query
  # @return [Pixiurge::Player,nil] The Player object or nil if there isn't one
  # @since 0.1.0
  def player_for_username(username)
    @players[username]
  end

  private
  def register_engine_item(item)
    return if @displayables[item.name] # Already have this one
    return if item.zone? # No displayable info for zones (yet?)
    return if item.is_a?(Demiurge::InertStateItem) # Nothing needed for InertStateItems
    if item.is_a?(::Demiurge::TmxLocation)
      @displayables[item.name] = ::Pixiurge::TiledLocation.new demi_item: item, name: item.name, engine_connector: self  # Build a Pixiurge location
    elsif item.agent?
      disp = item.get_action("$display")
      if disp && disp["block"] # This special action is used to pass the Display info through to a Display library.
        builder = Pixiurge::Display::DisplayBuilder.new(item, engine_connector: self)
        displayables = builder.built_objects
        raise("Only display one object per agent right now for item #{item.name.inspect}!") if displayables.size > 1
        raise("No display objects declared for item #{item.name.inspect}!") if displayables.size == 0
        @displayables[item.name] = displayables[0]  # Exactly one display object. Perfect.
      else
        # No Display information? Default to generic guy in a hat.
        layers = [ "male", "kettle_hat_male", "robe_male" ]
        @displayables[item.name] = ::Pixiurge::Humanoid.new layers, name: item.name, demi_item: item, engine_connector: self
      end

      # Is this a registration for a player's body?
      if @players[item.name]
        player = @players[item.name]
        player.displayable = @displayables[item.name]
      end

      show_displayable_to_players(@displayables[item.name])
    else
      STDERR.puts "Don't know how to register or display this item: #{item.name.inspect}"
    end
  end

  def each_player_for_location_name(location_name, &block)
    @players.each do |player_name, player|
      if player.displayable && player.displayable.location_name == location_name
        yield(player)
      end
    end
  end

  def show_displayable_to_players(displayable)
    return unless displayable.position # Agents and some other items are allowed to have no position and just be instantiable
    demi_item = displayable.demi_item
    loc_name, x, y = ::Demiurge::TmxLocation.position_to_loc_coords(displayable.position)
    each_player_for_location_name(loc_name) do |player|
      displayable.show_to_player(player)
    end

    loc = @engine.item_by_name(loc_name)
    if loc.is_a?(::Demiurge::TmxLocation)
      spritesheet = loc.tiles[:spritesheet]
      @players.each do |player_name, player|
        if player.displayable.location_name == loc_name
          # The new displayable and the player are in the same location
          player.show_sprites(displayable.name, displayable.spritesheet, displayable.spritestack)
          player.message "displayTeleportStackToPixel", displayable.stack_name, x * spritesheet[:tilewidth], y * spritesheet[:tileheight], {}
        end
      end
    end
  end

  def hide_displayable_from_players(displayable, position)
    position ||= displayable.demi_item.position
    return unless position
    if position  # Agents and some other items are allowed to have no position and just be instantiable
      loc_name, x, y = ::Demiurge::TmxLocation.position_to_loc_coords(position)
      loc = @engine.item_by_name(loc_name)
      if loc.is_a?(::Demiurge::TmxLocation)
        spritesheet = loc.tiles[:spritesheet]
        @players.each do |player_name, player|
          if player.displayable.location_name == loc_name
            # The new agent and the player are in the same location
            player.hide_sprites(displayable.name)
          end
        end
      end
    end
  end

  def show_location_to_player(player, position, location_do)
    spritesheet = location_do.spritesheet
    spritestack = location_do.spritestack

    loc_name = location_do.name

    # Show the location's sprites
    player.hide_all_sprites
    player.show_sprites(location_do.name, spritesheet, spritestack)
    x, y = ::Demiurge::TmxLocation.position_to_coords(position)
    player.send_instant_pan_to_pixel_offset spritesheet[:tilewidth] * x, spritesheet[:tileheight] * y

    # Anybody else there? Show them to this player.
    @displayables.each do |do_name, displayable|
      if displayable.location_name == loc_name
        displayable.show_to_player(player)
      end
    end
  end

  def add_player(player)
    @players[player.name] = player
    player.displayable = @displayables[player.name]
    unless player.displayable
      raise "Set the Player's Displayable before this!"
    end
    loc_name = player.displayable.location_name
    player_position = player.displayable.position
    loc_do = @displayables[loc_name]

    # Do we have a display object for that player's location?
    unless loc_do
      STDERR.puts "This player doesn't seem to be in a known TMX location, instead is in #{loc_name.inspect}!"
      return
    end

    show_location_to_player(player, player_position, loc_do)
  end

  # The logout action happens before this does, which may affect what's where.
  def remove_player(player)
    @players.delete(player.name)
  end

  # When new data comes in about things in the engine changing, this is what receives that notification.
  def notified(data)
    return if data["type"] == Demiurge::Notifications::TickFinished
    return if data["type"] == Demiurge::Notifications::MoveFrom
    return if data["type"] == Demiurge::Notifications::LoadStateStart

    # We subscribe to all events in all locations, and the move-from
    # and move-to have the same fields except location, zone and
    # type. So only pay attention to the move_to.
    if data["type"] == Demiurge::Notifications::MoveTo
      return notified_of_move_to(data)
    end

    if data["type"] == Demiurge::Notifications::LoadStateEnd
      @displayables.each_value do |displayable|
        displayable.demiurge_reloaded
      end
      return
    end

    if data["type"] == Demiurge::Notifications::IntentionCancelled
      acting_item = data["actor"]
      if @players[acting_item]
        # This was a player action that was cancelled
        player = @players[acting_item]
        player.message "displayTextAnimOverStack", player.displayable.stack_name, data["reason"], "color" => "#FFCCCC", "font" => "20px Arial", "duration" => 3.0
        return
      end
      return
    end

    if data["type"] == Demiurge::Notifications::IntentionApplied
      # For right now we don't need any kind of confirmations. But
      # when we do, this is where they come from.
      return
    end

    if data["type"] == "speech"
      text = data["words"] || "ADD WORDS TO SPEECH NOTIFICATION!"
      speaker = @engine.item_by_name(data["actor"])
      body = @displayables[data["actor"]]
      speaker_loc_name = speaker.location_name
      @players.each do |player_name, player|
        player_loc_name = player.displayable.location_name
        next unless player_loc_name == speaker_loc_name
        player.message "displayTextAnimOverStack", body.stack_name, text, "color" => data["color"] || "#CCCCCC", "font" => data["font"] || "20px Arial", "duration" => data["duration"] || 5.0
      end
      return
    end

    # This notification will catch new player bodies, instantiated agents and whatnot.
    if data["type"] == Demiurge::Notifications::NewItem
      item = @engine.item_by_name data["actor"]
      register_engine_item(item)
      return
    end

    STDERR.puts "Unhandled notification of type #{data["type"].inspect}...\n#{data.inspect}"
  end

  def notified_of_move_to(data)
    actor_do = @displayables[data["actor"]]
    x, y = ::Demiurge::TmxLocation.position_to_coords(data["new_position"])
    old_x = actor_do.x
    old_y = actor_do.y
    loc_name = data["new_location"]
    loc_do = @displayables[loc_name]
    if loc_do
      spritesheet = loc_do.spritesheet
      spritestack = loc_do.spritestack
    else
      STDERR.puts "Moving to a non-displayed location #{loc_name.inspect}, no display object found..."
    end

    actor_do.position = data["new_position"]

    # An object just moved to a new location - show it to everybody in the new location, if it's a displayable loction.
    if data["old_location"] != data["new_location"]
      show_displayable_to_players(actor_do) if loc_do
    end

    # Is it a player that just moved? If so, update them specifically.
    acting_player = @players[data["actor"]]
    if acting_player
      if data["old_location"] != data["new_location"]
        ## Show the new location's sprites to the player who is moving, if the new location has sprites
        show_location_to_player(acting_player, data["new_position"], @displayables[loc_name]) if loc_do
      else
        # Player moved in same location, pan to new position
        actor_do.move_for_player(acting_player, data["old_position"], data["new_position"], { "duration" => 0.5 })
        acting_player.send_instant_pan_to_pixel_offset spritesheet[:tilewidth] * x, spritesheet[:tileheight] * y
      end
    end

    # Whether it's a player moving or something else, update all the
    # players who just saw the item move, disappear or appear.
    @players.each do |player_name, player|
      next if player_name == data["actor"]  # Already handled it if this player is the one moving.
      player_loc_name = player.displayable ? player.displayable.location_name : nil
      next unless player_loc_name            # Player has no location? We don't update them.

      if data["old_location"] == data["new_location"]
        next unless player_loc_name == data["new_location"]
        actor_do.move_for_player(player, data["old_position"], data["new_position"], { "duration" => 0.5 })
      elsif player_loc_name == data["old_location"]
        # The item changed rooms and the player is in the old
        # location. Hide the item.
        actor_do.hide_from_player(player)
      elsif player_loc_name == data["new_location"]
        # The item changed rooms and the player is in the new
        # location. Show the item, if it moved to a displayable
        # location.
        actor_do.show_to_player(player) if loc_do
      end
    end
  end
end
