require "demiurge"
require "faye/websocket"

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

  # Legal simulation-related hash options for {#initialize}
  SIMULATION_OPTIONS = [ :engine, :engine_text, :engine_files, :engine_dsl_dir, :engine_restore_statefile, :ms_per_tick, :autosave_ticks, :autosave_path ]

  # Legal hash options for {#initialize}
  CONSTRUCTOR_OPTIONS = SIMULATION_OPTIONS + [ :default_width, :default_height, :no_start_simulation ]

  # Constructor. Create the EngineConnector, which will act as a
  # gateway between the simulation engine and the network and
  # authorization interfaces (a.k.a. "the app".) The engine and any
  # additional settings will be configured after the object is
  # allocated.
  #
  # Unless the :no_start_simulation option is true,
  # {#start_simulation} will be called with the appropriate
  # simulation-related options to create the simulation engine.
  #
  # @see #start_simulation
  # @param pixi_app [Pixiurge::App] The Pixiurge App for assets and network interactions
  # @param options [Hash] Options for the EngineConnector
  # @option options [Integer] :default_width Default width for display if unspecified
  # @option options [Integer] :default_height Default height for display if unspecified
  # @option options [Boolean] :no_start_simulation Don't allocate an engine or start the simulation - that will be handled later or outside Pixiurge
  # @option options [Demiurge::Engine] :engine Demiurge simulation engine; if this option is passed, use it instead of creating a new one
  # @option options [Array] :engine_text Array of 2-element arrays, each with a filename followed by World File DSL; passed to {Demiurge::DSL.engine_from_dsl_text} to create engine
  # @option options [Array] :engine_files Array of filenames of World File DSL code; passed to {Demiurge::DSL.engine_from_dsl_files} to create engine.
  # @option options [String] :engine_dsl_dir Path to a directory containing DSL files and (optionally) DSL Ruby extensions
  # @option options [String] :engine_restore_statefile Path to most recent statedump file, which will be restored to the engine state
  # @option options [Integer] :ms_per_tick How many milliseconds should occur between simulation ticks
  # @option options [Integer] :autosave_ticks Dump state automatically every time this many ticks occur; set to 0 for no automatic state-dump; defaults to 600
  # @option options [String] :autosave_path Write the autosave to this path; you can use %TICKS% in the path for a number of ticks completed; defaults to "state/autosave_%TICKS%.json"
  # @since 0.1.0
  def initialize(pixi_app, options = {})
    illegal_options = options.keys - CONSTRUCTOR_OPTIONS
    raise("Illegal options passed to EngineConnector#initialize: #{illegal_options.inspect}!") unless illegal_options.empty?

    @app = pixi_app
    @players = {}      # Mapping of player name strings to Player objects (not Displayable objects or Demiurge items)
    @displayables = {} # Mapping of item names to the original registered source, and display objects such as TileAnimatedSprites
    @default_width = options[:default_width] || 640
    @default_height = options[:default_height] || 480
    @ms_per_tick = 500

    unless options[:no_start_simulation]
      # @todo Replace this with Hash#slice and require a higher minimum Ruby version
      sim_options = {}
      SIMULATION_OPTIONS.each { |opt| options.has_key?(opt) && sim_options[opt] = options[opt] }
      start_simulation(sim_options)
    end
  end

  # Make sure the simulation is running. Supply parameters about how
  # exactly that should happen. You can pass in a constructed engine,
  # or parameters for how to create one.
  #
  # You should pass in up to one of :engine, :engine_text,
  # :engine_files or :engine_dsl_dir to create the Engine or use a
  # created Engine. If you don't pass one, Pixiurge will assume an
  # :engine_dsl_dir of "world" under the {Pixiurge::App#root_dir}.
  #
  # A DSL directory, if one is included, will assume that any Ruby
  # file under an extensions directory or subdirectory will be loaded
  # directly as Ruby code. Any Ruby file *not* under an extensions
  # directory or subdirectory will be loaded as Demiurge World File
  # DSL.
  #
  # By default the Demiurge Engine will run at 2 ticks per second, or
  # 500 milliseconds per tick. You can alter this with the
  # :ms_per_tick option.
  #
  # By default, Pixiurge will save state automatically every 600 ticks
  # into a timestamped file in the "state" subdirectory. The
  # :autosave_ticks option can be set to a number of ticks for how
  # often to save, or 0 for no autosave. You can set it to 0 and
  # configure an autosave yourself by subscribing to the
  # {Demiurge::Notifications::TickFinished} notification as well. The
  # :autosave_path option says where to put the autosave file when it
  # occurs. The substring "%TICKS%" will be replaced with the number
  # of ticks completed if it is part of the :autosave_path.
  #
  # @param options [Hash] Options for how to run the Demiurge engine.
  # @option options [Demiurge::Engine] :engine Demiurge simulation engine; if this option is passed, use it instead of creating a new one
  # @option options [Array] :engine_text Array of 2-element arrays, each with a filename followed by World File DSL; passed to {Demiurge::DSL.engine_from_dsl_text} to create engine
  # @option options [Array] :engine_files Array of filenames of World File DSL code; passed to {Demiurge::DSL.engine_from_dsl_files} to create engine.
  # @option options [String] :engine_dsl_dir Path to a directory containing DSL files and (optionally) DSL Ruby extensions
  # @option options [String] :engine_restore_statefile Path to most recent statedump file, which will be restored to the engine state
  # @option options [Integer] :ms_per_tick How many milliseconds should occur between simulation ticks
  # @option options [Integer] :autosave_ticks Dump state automatically every time this many ticks occur; set to 0 for no automatic state-dump; defaults to 600
  # @option options [String] :autosave_path Write the autosave to this path; you can use %TICKS% in the path for a number of ticks completed; defaults to "state/autosave_%TICKS%.json"
  # @since 0.1.0
  # @return [void]
  def start_simulation(options = {})
    raise("Simulation is already configured!") if @engine_configured || @engine_started

    illegal_options = options.keys - SIMULATION_OPTIONS
    raise "Passed illegal options to #start_simulation! #{illegal_options.inspect}" unless illegal_options.empty?

    if options[:engine]
      engine = options[:engine]
    elsif options[:engine_text]
      engine = Demiurge::DSL.engine_from_dsl_text options[:engine_text]
    elsif options[:engine_files]
      engine = Demiurge::DSL.engine_from_dsl_files options[:engine_files]
    else
      dsl_dir = options[:engine_dsl_dir] || File.join(@root_dir, "world")

      # Require all Ruby extensions under the World dir
      ruby_extensions = Dir["#{dsl_dir}/**/extensions/**/*.rb"]
      ruby_extensions.each { |filename| require filename }

      # Load all Worldfile non-Ruby-extension files as World File DSL
      dsl_files = Dir["#{dsl_dir}/**/*.rb"] - ruby_extensions
      engine = Demiurge::DSL.engine_from_dsl_files *dsl_files
    end

    @ms_per_tick = options[:ms_per_tick] || 500
    @autosave_ticks = options[:autosave_ticks] || 600
    @autosave_path = options[:autosave_path] || "state/autosave_%TICKS%.json"

    # Subscribe to notifications and sync up with all existing engine
    # objects before we actually start the simulation.
    hook_up_engine(engine)

    if options[:engine_restore_statefile]
      last_statefile = options[:engine_restore_statefile]
      puts "Restoring state data from #{last_statefile.inspect}."
      state_data = MultiJson.load File.read(last_statefile)
      @engine.load_state_from_dump(state_data)
    end
    @engine_configured = true

    #start_engine_periodic_timer
  end

  # It's hard to tell where to call this. It can only happen after
  # EventMachine's loop is started. There's a lot of weirdness with
  # trying to ensure_running ourselves, because then Thin won't run
  # its own event loop, and there's constant problems with running off
  # the end of the main thread. At this point, we're winding up doing
  # a horrible thing in config_ru.rb for the event loop.
  #
  # @api private
  def start_engine_periodic_timer
    counter = 0

    @engine_started = true
    EM.add_periodic_timer(0.001 * @ms_per_tick) do
      # Step game content forward by one tick
      begin
        @engine.advance_one_tick
        admin_item = @engine.item_by_name("admin")
        ticks = admin_item.state["ticks"]
        counter += 1
        if @autosave_ticks != 0 && ticks % @autosave_ticks == 0
          puts "Writing periodic statefile, every #{@autosave_ticks.inspect} ticks..."
          ss = @engine.structured_state
          statefile = @autosave_path.gsub("%TICKS%", ticks.to_s)
          File.open(statefile, "w") do |f|
            f.print MultiJson.dump(ss, :pretty => true)
          end
        end
      rescue
        STDERR.puts "Error trace:\n#{$!.message}\n#{$!.backtrace.join("\n")}"
        STDERR.puts "Error when advancing engine state. Dumping state, skipping tick."
        ss = @engine.structured_state
        File.open("state/error_statefile.json", "w") do |f|
          f.print MultiJson.dump(ss, :pretty => true)
        end
      end
    end
  end

  def thin_eventmachine_loop(rack_app, port, ssl_key_path, ssl_cert_path)
    # No luck with Puma - for now, hardcode using Thin
    Faye::WebSocket.load_adapter('thin')

    EventMachine.run {
      thin = Rack::Handler.get('thin')
      thin.run(rack_app, :Port => port) do |server|
        server.ssl_options = {
          # Supported options: http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection:start_tls
          :private_key_file => ssl_key_path,
          :cert_chain_file  => ssl_cert_path,
          :verify_peer => false,
        }
        server.ssl = true
      end
      Signal.trap("INT")  { STDERR.puts "Caught SIGINT, telling EventMachine to stop..."; EventMachine.stop }
      Signal.trap("TERM") { STDERR.puts "Caught SIGTERM, telling EventMachine to stop..."; EventMachine.stop }

      # And now, the purpose of this whole loop - allowing WebSockets,
      # the Thin server *and* a single periodic timer to all run at
      # once without multiple threads, and still have the timer start
      # when the server does. *sigh*
      start_engine_periodic_timer
    }
    STDERR.puts "Killed by SIGINT or SIGTERM... Exiting!"
  end

  private

  def hook_up_engine(engine)
    @engine = engine

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

    # Next, subscribe to appropriate events for the Pixiurge App -
    # these let us handle player network connections. These events are
    # sent immediately, not when we flush notifications from the
    # Demiurge engine.
    @app.on_event "player_login" do |username|
      demi_item = @engine.item_by_name(username)
      if demi_item
        raise("There is already a body with reserved name #{username} not marked for this player!") unless demi_item.state["$player_body"] == username
      else
        # No body yet? Send a signal to indicate that we need one.
        @app.send("send_event", "player_create_body", username)
        demi_item = @engine.item_by_name(username)
        unless demi_item
          # Still no body? Either there was no signal handler, or it did nothing.
          STDERR.puts "No player body was created in Demiurge for #{username.inspect}! No login for you!"
          return
        end
        demi_item.state["$player_body"] = username
        demi_item.run_action("create") if demi_item.get_action("create")
        # Now register the player's body with the EngineConnector to make sure we have a Displayable for it
        register_engine_item(demi_item)
        displayable = @displayables[username][:displayable]
        unless(displayable)
          raise "No displayable item was created for user #{username}'s body!"
        end
      end
      demi_item.run_action("login") if demi_item.get_action("login")
      ws = @app.websocket_for_username username
      displayable = @displayables[username][:displayable]
      player = Pixiurge::Player.new websocket: ws, name: username, displayable: displayable, display_settings: display_settings, engine_connector: self
      add_player(player)
    end
    @app.on_event "player_logout" do |username|
      remove_player(@players[username]) if @players[username]
    end
    @app.on_event "player_reconnect" do |username|
    end
  end

  public

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
    @displayables[item_name][:displayable]
  end

  # Query for a Player object by account name, which should match the
  # Demiurge username for that player's body if there is one.
  #
  # @param username [String] The account name to query
  # @return [Pixiurge::Player,nil] The Player object or nil if there isn't one
  # @since 0.1.0
  def player_by_username(username)
    @players[username]
  end

  private

  def display_settings
    {
      "width" => @default_width,
      "height" => @default_height,
      "ms_per_tick" => 300,
    }
  end

  public

  def displayable_for_item(item)
    return if item.is_a?(Demiurge::InertStateItem) # Nothing needed for InertStateItems

    # See if the item uses a custom Displayable set via the "display"
    # block in the World Files. If so, use it.
    disp_action = item.get_action("$display")
    if disp_action && disp_action["block"] # This special action is used to pass the Display info through to a Display library.
      builder = Pixiurge::Display::DisplayBuilder.new(item, engine_connector: self, &(disp_action["block"]))
      displayables = builder.built_objects
      raise("Only display one object per agent right now for item #{item.name.inspect}!") if displayables.size > 1
      raise("No display objects declared for item #{item.name.inspect}!") if displayables.size == 0
      return displayables[0]  # Exactly one display object. Perfect.
    end

    if item.is_a?(::Demiurge::Tmx::TmxLocation)
      return ::Pixiurge::Display::TmxMap.new item.tile_cache_entry, name: item.name, engine_connector: self  # Build a Pixiurge location
    elsif item.agent?
      # No Display information? Default to generic guy in a hat.
      layers = [ "male", "kettle_hat_male", "robe_male" ]
      raise "Nope! Haven't implemented a default displayable for agents yet!"
    end

    if item.zone?
      return ::Pixiurge::Display::Invisible.new name: item.name, engine_connector: self
    end

    # If we got here, we have no idea how to display this.
    nil
  end

  def register_engine_item(item)
    if @displayables[item.name] # Already have this one
      return if @displayables[item.name][:source] == :demiurge  # Duplicate registration, it's fine
      raise "Displayable name #{item.name.inspect} is already used by source object #{@displayables[item.name][:source].inspect}! Can't re-register as #{item.inspect}!"
    end

    displayable = displayable_for_item(item)
    if displayable
      @displayables[item.name] = { displayable: displayable, source: :demiurge }
      displayable.position = item.position if item.position
      show_displayable_to_players(displayable)
      return
    end

    # What if there's no Displayable for this item? That might be okay or might not.
    return if item.is_a?(::Demiurge::InertStateItem) # Nothing needed for InertStateItems

    STDERR.puts "Don't know how to register or display this item: #{item.name.inspect}"
  end

  # This method adds a new Displayable object which does *not*
  # correspond to a Demiurge item.  This is useful for Displayables
  # for non-Demiurge objects such as dialog boxes or title screens,
  # and for components of larger objects (e.g. a player's shadow)
  # which are *attached* to a Demiure item but don't really
  # *represent* a Demiurge item.
  #
  # Among other things this reserves a name for the Displayable in the
  # EngineConnector.  A Displayable isn't allowed to share a name with
  # any other Displayable nor with any item in the Demiurge engine.
  # For this reason, a common convention for "sub-Displayables" is to
  # use the parent Displayable's name followed by an at-sign and a
  # name or number. The at-sign isn't a legal character for Demiurge
  # item names, so this makes it clear what the "attached" item is and
  # guarantees uniqueness.
  #
  # @param object [Pixiurge::Displayable] The new Displayable to register
  # @return [void]
  # @since 0.1.0
  def register_displayable_object(object)
    if @displayables[object.name] # Already have this one
      return if @displayables[object.name][:source] == object  # Duplicate registration, which is fine
      raise "Already have a Displayable named #{object.name.inspect} registered by #{@displayables[object.name][:source].inspect}! Can't re-register as Displayable #{object.inspect}!"
    end
    @displayables[object.name] = { displayable: object, source: object }
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
    @displayables.each do |disp_name, disp_hash|
      disp = disp_hash[:displayable]
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
        player.destroy_displayable(displayable.name)
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
    player.destroy_all_displayables
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

  # One interesting difficulty here... Everything going on here
  # generates notifications. We don't want to just flush notifications
  # in the engine, because this may be in between timesteps. But we
  # also don't want to have a bunch of player body movements pile up
  # pre-login.
  def add_player(player)
    @players[player.name] = player
    unless player.displayable
      raise "Set the Player's Displayable before this!"
    end
    loc_name = player.displayable.location_name
    player_position = player.displayable.position
    loc_do = @displayables[loc_name][:displayable]

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

  # This is the internal constant to exit early from the notification
  # routine if the notification is of any of these types. Anything
  # here requires no direct response from the EngineConnector, for a
  # variety of different reasons.
  IGNORED_NOTIFICATION_TYPES = {
    # Tick finished? Great, no change.
    Demiurge::Notifications::TickFinished => true,

    # MoveFrom? We handle the corresponding MoveTo instead.
    Demiurge::Notifications::MoveFrom => true,

    # LoadStateStart/Verify or LoadWorldStart notifications? We'll make changes when they complete
    Demiurge::Notifications::LoadStateStart => true,
    Demiurge::Notifications::LoadWorldStart => true,
    Demiurge::Notifications::LoadWorldVerify => true,

    # Player logout or reconnect? Already handled. This EngineConnector was the object that sent this notification anyway.
    Pixiurge::Notifications::PlayerLogout => true,
    Pixiurge::Notifications::PlayerReconnect => true,
  }

  # When new data comes in about things in the engine changing, this is what receives that notification.
  def notified(data)
    # First, ignore a bunch of notifications we don't care about
    return if IGNORED_NOTIFICATION_TYPES[data["type"]]

    # We subscribe to all events in all locations, and the move-from
    # and move-to have the same fields except location, zone and
    # type. So only pay attention to the move_to.
    if data["type"] == Demiurge::Notifications::MoveTo
      return notified_of_move_to(data)
    end

    if data["type"] == Demiurge::Notifications::LoadStateEnd
      # What to do here? Displayables don't care about this any more. Does anything in Pixiurge?
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
        player.message Pixiurge::Protocol::Outgoing::DISPLAY_EFFECT_TEXT, "", { "at" => player.displayable.name, "text" => data["reason"], "color" => "#FFCCCC", "font" => "20px Arial", "duration" => 3.0 }
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
      body = @displayables[data["actor"]][:displayable]
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
    actor_do = @displayables[data["actor"]][:displayable]
    x, y = ::Demiurge::TiledLocation.position_to_coords(data["new_position"])
    loc_name = data["new_location"]
    loc_do = @displayables[loc_name] ? @displayables[loc_name][:displayable] : nil
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
        set_player_backdrop(acting_player, data["new_position"], @displayables[loc_name][:displayable])
      else
        # Player moved in same location, pan to new position
        acting_player.move_displayable(actor_do, data["old_position"], data["new_position"])
        acting_player.pan_to_coordinates(x, y)
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
        actor_do.move_for_player(player, data["old_position"], data["new_position"], {})

        # Second case: moving player changed rooms and we're in the old one
      elsif player_loc_name == data["old_location"]
        # The item changed rooms and the player is in the old
        # location. Hide the item.
        player.destroy_displayable(actor_do)

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
