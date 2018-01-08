require "pixiurge/protocol"

# Pixiurge::App is the parent class of Pixiurge applications (games).
# By inheriting from this and overriding various handlers, your
# Pixiurge server-side application can respond appropriately to the
# Javascript/Pixi client-side browsers.
#
# @since 0.1.0
class Pixiurge::App
  attr :record_traffic
  attr :debug
  attr :incoming_traffic_logfile
  attr :outgoing_traffic_logfile

  # Constructor for Pixiurge App base class.
  #
  # @since 0.1.0
  def initialize
    @debug = true  # For now, default to true
    @record_traffic = true # For now, default to true
    @incoming_traffic_logfile = "log/incoming_traffic.json"
    @outgoing_traffic_logfile = "log/outgoing_traffic.json"
  end

  # Create a websocket handler for the Pixiurge app.
  #
  # @param env [Rack::Env] The Rack environment
  # @api private
  # @since 0.1.0
  def websocket_handler(env)
    ws = Faye::WebSocket.new(env)

    ws.on :open do |event|
      puts "Socket open" if @debug
      on_open(ws, event) if self.respond_to?(:on_open)
    end

    ws.on :message do |event|
      File.open(@incoming_traffic_logfile, "a") { |f| f.write event.data + "\n" } if @record_traffic
      data = MultiJson.load event.data
      handle_message ws, data
    end

    ws.on :error do |event|
      on_error(ws, event) if self.respond_to?(:on_error)
    end

    ws.on :close do |event|
      on_close(ws, event) if self.respond_to?(:on_close)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response
  end

  # This handler dispatches to on_auth_message,
  # on_player_action_message or on_message, depending on the incoming
  # message type and what handlers the app subtype has defined.
  #
  # @param ws [Websocket] The Faye websocket object
  # @param data [Hash] Deserialized JSON data sent from the client
  # @api private
  # @since 0.1.0
  def handle_message(ws, data)
    if data[0] == Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE
      return on_auth_message(ws, data[1], *data[2]) if self.respond_to?(:on_auth_message)
    end
    if data[0] == Pixiurge::Protocol::Incoming::ACTION_MSG_TYPE
      return on_player_action_message(ws, data[1], *data[2]) if self.respond_to?(:on_player_action_message)
    end
    return on_message(ws, data) if self.respond_to?(:on_message)
    raise "No handler for message! #{data.inspect}"
  end

  # Below this line: For Pixiurge's Config.ru handling
  ####################################################

  # Call this with your application's web root directory.
  # This is useful for finding your application's assets,
  # such as graphics, images and maps. Later calls such
  # as static_dirs and coffeescript_dirs are relative to
  # this root.
  #
  # @param dir [String] The path to your app's web root.
  # @since 0.1.0
  def root_dir dir
    @root_dir = File.absolute_path(dir)
  end

  # In config.ru, call this as "Pixiurge.rack_builder self" to allow Pixiurge to
  # add middleware to your Rack stack. Pixiurge will add its own /pixiurge directory
  # in order to provide access to the Pixiurge debug or release Javascript.
  #
  # @param builder [Rack::Builder] The top level of your config.ru Rack Builder
  # @since 0.1.0
  def rack_builder builder
    @rack_builder = builder

    coffee_root = File.join(__dir__, "..", "..")
    @rack_builder.use Rack::Coffee, :root => coffee_root, :urls => "/pixiurge"
  end

  # Call this to add coffeescript directories for your own app, if you're using
  # CoffeeScript.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def coffeescript_dirs *dirs
    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    dirs = [*dirs].flatten
    @rack_builder.use Rack::Coffee, :root => (@root_dir + "/"), :urls => dirs.map { |d| "/" + d }
  end

  # To have Pixiurge serve static directories of Javascript or assets, call this with the appropriate list of directory names.
  # All directory names are relative to the web root you passed to Pixiurge.root_dir.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def static_dirs *dirs
    dirs = [*dirs].flatten

    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    @rack_builder.use Rack::Static, :root => @root_dir, :urls => dirs.map { |d| "/" + d }
  end

  # To have Pixiurge serve individual static files such as index.html, call this with the appropriate list of file paths.
  # All paths are relative to the web root you passed to Pixiurge.root_dir.
  #
  # @see Pixiurge.static_dirs
  # @param files [String, Array<String>] The file path or array of file paths, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def static_files *files
    @static_files ||= []
    @static_files.concat [*files].flatten
  end

  # Get the final, built Rack handler from Pixiurge with all the specified middleware and websocket handling.
  #
  # @see Pixiurge.root_dir
  # @see Pixiurge.static_dirs
  # @see Pixiurge.coffeescript_dirs
  # @since 0.1.0
  def handler
    @static_files ||= []
    static_files = @static_files.map { |f| "/" + f }
    lambda do |env|
      if Faye::WebSocket.websocket? env
        @app.websocket_handler env
      else
        if static_files.include?(env["PATH_INFO"])
          file = env["PATH_INFO"]
          path = File.join(@root_dir, file)
          return [200, {'Content-Type' => 'text/html'}, [File.read(path)]]
        else
          return [404, {}, [""]]
        end
      end
    end
  end
end
