require "pixiurge/config_ru"
require "rack"
require "demiurge"

# Get the absolute path for the game root
PIXI_APP_ROOT = File.expand_path(__dir__)

class HatRelay < Pixiurge::AuthenticatedApp
  attr_reader :engine_connector
  attr_reader :engine

  def initialize
    # Configure Pixiurge AuthenticatedApp
    options = {
      :debug => false,
      :record_traffic => false,
      :incoming_traffic_logfile => "log/incoming_traffic.json",
      :outgoing_traffic_logfile => "log/outgoing_traffic.json",
      :accounts_file => "#{__dir__}/accounts.json"
    }
    super(options)

    # We should restore from the most recent JSON statefile in the
    # state directory By default we use modification time instead of
    # creation time because if the same filename gets written
    # repeatedly, we *do* want it to count as the most recent.
    last_statefile = (Dir["state/*.json"].sort_by { |f| File.mtime(f) })[-1]

    # Options for the EngineConnector
    options = {
      # Where are the Demiurge World Files?
      :engine_dsl_dir => "#{PIXI_APP_ROOT}/world",

      # Restore state from the last available statefile, if any
      #:engine_restore_statefile => last_statefile,

      # Configure automatic statedumps
      :autosave_ticks => 600,
      :autosave_path => "state/autosave_%TICKS%.json",

      # If not configured, default to this window size in the browser
      :default_width => 800,
      :default_height => 600,
    }
    @engine_connector = Pixiurge::EngineConnector.new(self, options)
    @engine = @engine_connector.engine

    # You can set up handlers as shown below with inherited methods or
    # you can use on_event("event name") here. They do the same thing.
  end

  # This handler lets you react to Websocket messages sent from this player's browser.
  def on_player_action(username, args)
    player = @engine_connector.player_by_username(username)
    player_demi_item = @engine.item_by_name(username)

    action_name = args[0]

    # This action is if you want to send move messages without bothering to send them as keycodes
    if action_name == "move"
      player_demi_item.queue_action "move", args[1]
      return
    end

    if action_name == "keypress"
      data = args[1]
      keycode = data["code"]
      if keycode == Pixiurge::Protocol::Incoming::Keycode::LEFT_ARROW
        player_demi_item.queue_action "move", "left"
      elsif keycode == Pixiurge::Protocol::Incoming::Keycode::RIGHT_ARROW
        player_demi_item.queue_action "move", "right"
      elsif keycode == Pixiurge::Protocol::Incoming::Keycode::UP_ARROW
        player_demi_item.queue_action "move", "up"
      elsif keycode == Pixiurge::Protocol::Incoming::Keycode::DOWN_ARROW
        player_demi_item.queue_action "move", "down"
      else
        STDERR.puts "Received keycode #{keycode.inspect}, but there's no handler!"
      end
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

pixi_app = HatRelay.new

rack_builder = Rack::Builder.new do
  file = File.new File.join(__dir__, "log", "http_requests.txt"), "a"
  file.sync = true
  use Rack::CommonLogger, file

  use Rack::ShowExceptions if ["development", ""].include?(ENV["RACK_ENV"].to_s)  # Useful for debugging, turn off in production

  EM.error_handler do |e|
    STDERR.puts "ERROR: #{e.message}\n#{e.backtrace.join "\n"}\n"
  end

  pixi_app.rack_builder self
  pixi_app.root_dir __dir__
  pixi_app.root_redirect "/html/index.html"
  #pixi_app.coffeescript_dirs "hat_relay"  # Optional for CoffeeScript front-end files
  #pixi_app.static_dirs "tiles", "sprites", "vendor_js", "ui", "static"   # Optional for any static front-end files such as graphics, sounds, HTML or scripts
  pixi_app.static_dirs "sprites"
  pixi_app.static_files "index.html"  # Optional for individual static files
  pixi_app.tmx_dirs "tmx"

  pixi_app.tilt_dirs "html"

  run pixi_app.handler
end

rack_app = rack_builder.to_app

# This method doesn't return, it just runs the loop forever.
pixi_app.engine_connector.thin_eventmachine_loop(rack_app, ENV['PIXIURGE_PORT'].to_i, ENV['PIXIURGE_KEY_FILE'], ENV['PIXIURGE_CERT_FILE'])
