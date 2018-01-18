require "pixiurge"
require "demiurge"

CANVAS_WIDTH = 640
CANVAS_HEIGHT = 480
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

    @engine_connector = Pixiurge::EngineConnector.new(@engine, self)
  end

  # @todo: There should be a parent-class method that hooks up action names that match to in-Demiurge player actions
  def on_player_message(websocket, action_name, *args)
    puts "Got player action: #{action_name.inspect} / #{args.inspect}"
    player = player_by_websocket(websocket) # LoginUnique defines player_by_websocket and player_by_name
    if action_name == "move"
      player.demi_item.queue_action "move", args[0]
      return
    end
    raise "Unknown player action #{action_name.inspect} with args #{args.inspect}!"
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
