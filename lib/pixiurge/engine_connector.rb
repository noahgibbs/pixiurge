require "demiurge"

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
  attr_reader :app

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
      player = Pixiurge::Player.new websocket: ws, name: username, displayable: displayable, display_settings: display_settings, engine_connector: self
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

  def display_settings
    { "ms_per_tick" => 300 }
  end

  def displayable_for_item(item)
    return if item.is_a?(Demiurge::InertStateItem) # Nothing needed for InertStateItems

    # See if the item uses a custom Displayable set via the "display"
    # block in the World Files. If so, use it.
    disp_action = item.get_action("$display")
    if disp_action && disp_action["block"] # This special action is used to pass the Display info through to a Display library.
      builder = Pixiurge::Display::DisplayBuilder.new(item, engine_connector: self)
      displayables = builder.built_objects
      raise("Only display one object per agent right now for item #{item.name.inspect}!") if displayables.size > 1
      raise("No display objects declared for item #{item.name.inspect}!") if displayables.size == 0
      return displayables[0]  # Exactly one display object. Perfect.
    end

    if item.is_a?(::Demiurge::Tmx::TmxLocation)
      return ::Pixiurge::Display::TmxMap.new demi_item: item, name: item.name, engine_connector: self  # Build a Pixiurge location
    elsif item.agent?
      # No Display information? Default to generic guy in a hat.
      layers = [ "male", "kettle_hat_male", "robe_male" ]
      return ::Pixiurge::Display::Humanoid.new layers, name: item.name, demi_item: item, engine_connector: self
    end

    # If we got here, we have no idea how to display this.
    nil
  end

  def register_engine_item(item)
    return if @displayables[item.name] # Already have this one

    displayable = displayable_for_item(item)
    if displayable
      @displayables[item.name] = displayable
      show_displayable_to_players(displayable)
      return
    end

    # What if there's no Displayable for this item? That might be okay or might not.

    return if item.is_a?(Demiurge::InertStateItem) # Nothing needed for InertStateItems
    return if item.zone? # No displayable info for zones, you're not supposed to see them

    STDERR.puts "Don't know how to register or display this item: #{item.name.inspect}"
  end

  def each_player_for_location_name(location_name, options = { :except => [] }, &block)
    @players.each do |player_name, player|
      next if options[:except].include?(player) || options[:except].include?(player_name)
      if player.displayable && player.displayable.location_name == location_name
        yield(player)
      end
    end
  end

  def each_displayable_for_location_name(location_name, &block)
    @displayables.each do |disp_name, disp|
      if disp.location_name == location_name
        yield(disp)
      end
    end
  end

  def show_displayable_to_players(displayable, options = { :except => []})
    return unless displayable.position # Agents and some other items are allowed to have no position and just be instantiable
    loc_name = displayable.position.split("#")[0]
    each_player_for_location_name(loc_name, options) do |player|
      player.show_displayable(displayable)
    end
  end

  def hide_displayable_from_players(displayable, position)
    position ||= displayable.demi_item.position
    return unless position

    loc_name = position.split("#")[0]
    loc = @engine.item_by_name(loc_name)
    if loc.is_a?(::Demiurge::Tmx::TmxLocation)
      each_player_for_location_name(loc_name) do |player|
        player.hide_displayable(displayable.name)
      end
    end
  end

  # @todo Should the backdrop be marked as special somehow? Make it
  #   clear that it winds up under everything else?  PIXI.js doesn't
  #   really do Z coordinates for most things, but right now anything
  #   that gets "lucky" enough to get displayed before the backdrop
  #   would become permanently invisible. There might be some
  #   constellation of events where that could happen.
  def set_player_backdrop(player, player_position, location_do)
    loc_name = location_do.name

    # Show the location's sprites
    player.hide_all_displayables
    player.show_displayable(location_do)
    x, y = ::Demiurge::TiledLocation.position_to_coords(player_position)
    x ||= 0
    y ||= 0
    player.send_instant_pan_to_pixel_offset location_do.block_width * x, location_do.block_height * y

    # Anybody or anything else there? Show them to this player.
    each_displayable_for_location_name(location_do.name) do |displayable|
      player.show_displayable(displayable)
    end
  end

  def add_player(player)
    @players[player.name] = player
    unless player.displayable
      raise "Set the Player's Displayable before this!"
    end
    loc_name = player.displayable.location_name
    player_position = player.displayable.position
    loc_do = @displayables[loc_name]

    # Do we have a display object for that player's location?
    unless loc_do
      STDERR.puts "This player doesn't seem to be in a known displayable location, instead is in #{loc_name.inspect}!"
      return
    end

    set_player_backdrop(player, player_position, loc_do)
  end

  # The logout action happens before this does, which may affect what's where.
  def remove_player(player)
    @players.delete(player.name)
  end

  # When new data comes in about things in the engine changing, this is what receives that notification.
  def notified(data)
    # First, ignore a bunch of notifications we don't care about
    return if data["type"] == Demiurge::Notifications::TickFinished
    return if data["type"] == Demiurge::Notifications::MoveFrom
    return if data["type"] == Demiurge::Notifications::LoadStateStart
    return if data["type"] == Demiurge::Notifications::LoadWorldVerify
    return if data["type"] == Demiurge::Notifications::LoadWorldStart

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

    if data["type"] == Demiurge::Notifications::LoadWorldEnd
      # Not entirely clear what we do here. Demiurge has just reloaded
      # the World files, which may result in a bunch of changes...
      # Though if objects get created, destroyed or moved, that should
      # get separate notifications which should finish before this
      # happens. We don't care that they're part of a World Reload --
      # if we did, we'd track the LoadWorldStart.
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
      @players.each do |player_name, player_obj|
        player_loc_name = player_obj.displayable.location_name
        next unless player_loc_name == speaker_loc_name
        player_obj.message "displayTextAnimOverStack", body.stack_name, text, "color" => data["color"] || "#CCCCCC", "font" => data["font"] || "20px Arial", "duration" => data["duration"] || 5.0
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
    x, y = ::Demiurge::TiledLocation.position_to_coords(data["new_position"])
    loc_name = data["new_location"]
    loc_do = @displayables[loc_name]
    unless loc_do
      STDERR.puts "Moving to a non-displayed location #{loc_name.inspect}, no display object found..."
      return
    end

    actor_do.position = data["new_position"]

    # Is it a player that just moved? If so, update them specifically.
    acting_player = @players[data["actor"]]
    if acting_player
      if data["old_location"] != data["new_location"]
        ## Hide the old location's Displayables and show the new
        ## location's Displayables to the player who is moving
        set_player_backdrop(acting_player, data["new_position"], @displayables[loc_name])
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
      player_loc_name = player.displayable.location_name

      # First case: moving player remained in the same room - update movement for anybody *in* that room
      if data["old_location"] == data["new_location"]
        next unless player_loc_name == data["new_location"]
        actor_do.move_for_player(player, data["old_position"], data["new_position"], { "duration" => 0.5 })

        # Second case: moving player changed rooms and we're in the old one
      elsif player_loc_name == data["old_location"]
        # The item changed rooms and the player is in the old
        # location. Hide the item.
        player.hide_displayable(actor_do)

        # Third case: moving player changed rooms and we're in the new one
      elsif player_loc_name == data["new_location"]
        # The item changed rooms and the player is in the new
        # location. Show the item, if it moved to a displayable
        # location.
        player.show_displayable(actor_do)
      end
    end
  end
end
