require "pixiurge"
require "demiurge"

TICK_MILLISECONDS = 300
TICKS_PER_SAVE = (60 * 1000 / TICK_MILLISECONDS)  # Every 1 minute

class Hat_relay < Pixiurge::AuthenticatedApp
  def initialize
    # Ruby extensions in the World Files? Load them.
    Dir["#{__dir__}/world/extensions/**/*.rb"].sort.each do |ruby_ext|
      require_relative ruby_ext
    end
    @engine = Demiurge::DSL.engine_from_dsl_files *Dir["world/**/*.rb"]

    # Configure Pixiurge AuthenticatedApp
    options = {
      "debug" => false,
      "record_traffic" => false,
      "incoming_traffic_logfile" => "log/incoming_traffic.json",
      "outgoing_traffic_logfile" => "log/outgoing_traffic.json",
      "accounts_file" => "accounts.json"
    }
    super(options)

    # If we restore state, we should do it before the EngineSync is
    # created.  Otherwise we have to replay a lot of "new item"
    # notifications or otherwise register a bunch of state with the
    # EngineSync.
    # @todo Sort this list by modification date
    last_statefile = [ "state/shutdown_statefile.json", "state/periodic_statefile.json", "state/error_statefile.json" ].detect do |f|
      File.exist?(f)
    end
    if last_statefile
      puts "Restoring state data from #{last_statefile.inspect}."
      state_data = MultiJson.load File.read(last_statefile)
      @engine.load_state_from_dump(state_data)
    else
      puts "No last statefile found, starting from World Files."
    end

    @engine_connector = Pixiurge::EngineConnector.new(@engine, self, :default_width => 800, :default_height => 600)

  end

  # This handler lets you react to Websocket messages sent from this player's browser.
  def on_player_message(username, action_name, *args)
    player = @engine_connector.player_by_username(username)
    if action_name == "move"
      player.demi_item.queue_action "move", args[0]
      return
    end
    raise "Unknown player action #{action_name.inspect} with args #{args.inspect}!"
  end

  # Instantiating a "player template" is a great, simple way to make a
  # new Demiurge object with interesting behavior, such as the player
  # actions. But any way you create a Demiurge object is fine.
  def on_player_create_body(username)
    player_template = @engine.item_by_name("player template")
    start_room = @engine.item_by_name("start location")
    x, y = start_room.tmx_object_coords_by_name("start location")
    body = @engine.instantiate_new_item(username, player_template, "position" => "start location##{x},#{y}")
  end

  # This sets up a "logout" action for the body. If you don't have one of those, you probably shouldn't do this.
  def on_player_logout(username)
    body = @engine.item_by_name(username)
    body.run_action("logout") if body && body.get_action("logout")
  end

  # Methods you can override for event handling: on_player_login,
  #   on_player_logout,
  #   on_player_create_body,
  #   on_player_message,
  #   on_player_reconnect,
  #   on_open,
  #   on_close,
  #   on_error,
  #   on_message,
  #   on_login
end
