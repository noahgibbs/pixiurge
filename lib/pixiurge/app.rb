require "pixiurge/protocol"

# This is an interface class that defines all handlers for a Pixiurge
# application. It's possible to inherit from it but then you must
# override all handlers and you won't get higher-level application
# functionality, which you probably want. Instead, inherit from
# {Pixiurge::AuthenticatedApp} or just {Pixiurge::App}. This class
# exists primarily for purposes of documentation.
#
# Here is a config.ru that sets up a very basic Pixiurge App:
# ```ruby
# require "pixiurge"
# # require_relative "my_pixiurge_app_file"
#
# # You can also set up normal Rack code here like logfiles or
# # EM.error_handler here.
#
# # Instead of Pixiurge::App, you can instantiate a child class here
# app = Pixiurge::App.new
# app.rack_builder self
# app.root_dir __dir__
# app.coffeescript_dirs "coffee"
# app.static_dirs "static"
# app.static_files "bobo.txt"
#
# run app.handler
# ```
#
# To detect what's happening with an App, you can add handlers for
# various sorts of events. You can use the
# {Pixiurge::AppInterface#on_event} method to subscribe to an event,
# or you can inherit from an app class (usually AuthenticatedApp) and
# add child methods. The name of the event is the same as the method
# without the "on_" prefix. The event and the methods take the same
# arguments. Here is an example using the {#on_close} method:
#
# ```
# class MyAppSubtype < Pixiurge::AuthenticatedApp
#   def on_close(ws, code, reason)
#     # Handler code goes here
#   end
# end
#
# # Or equivalently...
# app = Pixiurge::AuthenticatedApp.new
# app.on_event("close") do |ws, code, reason|
#   # Handler code goes here
# end
# ```
#
# You can implement most games by only implementing a straightforward
# higher-level interface and not directly dealing with authentication,
# websockets, etc. The high-level handlers assume you are using
# AuthenticatedApp or have implemented the same functionality. Here
# are high-level handlers you can implement:
#
# * {#on_player_login} - a new player has logged in
# * {#on_player_logout} - a player has logged out
# * {#on_player_message} - a message has been received from a player on the front end
# * {#on_player_reconnect} - a player has re-logged in, often from a new browser session
#
# Next are the message handlers that your app can define for the
# low-level message interface. Keep in mind that higher-level
# functionality with AuthenticatedApp may depend on existing methods
# for these, so you should call super as appropriate if you override
# the methods - this is not a problem with the event approach, and may
# be a reason to use events instead.
#
# * {#on_open} - message handler for a newly-opened connection
# * {#on_close} - connection has been closed
# * {#on_auth_message} - message handler for authentication messages
# * {#on_action_message} - message handler for player action messages
# * {#on_message} - generic message handler for non-auth, non-player-action messages
# * {#on_error} - an error has occurred in the websocket layer
# * {#on_login} - called when a user successfully logs in using built-in authentication (AuthenticatedApp only)
#
# And finally there's a low-level websocket message handler you can
# override, but it doesn't send events via on_event:
#
# * {#handle_message} - very low-level message handler, only use it if you're comfortable reading the source code
#
# Some of these handlers may already be defined by AuthenticatedApp,
# which will require you to call super() appropriately.
#
# The low-level message handlers tend to use websocket objects. A
# websocket object has a #send(message) method and a #close(code,
# reason) method. #send normally takes a String, and #close can be
# called without arguments if you don't know or want to provide a code
# or reason. For more detail on the Websocket object, see
# https://github.com/faye/faye-websocket-ruby/blob/master/lib/faye/websocket/api.rb
#
# @see Pixiurge::AuthenticatedApp
# @since 0.1.0
class Pixiurge::AppInterface
  # This handler will be called when a new websocket connection is
  # made. At this point we don't know what player/account the
  # connection is for, nor very much else about it. If you are
  # inheriting from AuthenticatedApp, the {#on_login} handler will
  # later associate this connection with an account username.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @return [void]
  # @since 0.1.0
  def on_open(ws)
    raise "Do not use AppInterface directly!"
  end

  # This handler will be called when a websocket connection is
  # closed. It can be used for cleaning up player-related data
  # structures.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param code [Integer] A Websocket protocol onclose status code (see https://tools.ietf.org/html/rfc6455)
  # @param reason [String] A reason for the websocket closing
  # @return [void]
  # @since 0.1.0
  def on_close(ws, code, reason)
    raise "Do not use AppInterface directly!"
  end

  # This is called if the websocket has a protocol error.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param message [String] The error message
  # @return [void]
  # @since 0.1.0
  def on_error(ws, message)
    raise "Do not use AppInterface directly!"
  end

  # This handler is for authentication messages. By default,
  # AuthenticatedApp will define one for you, though you may wish to
  # override or completely replace it. The msg_subtype is normally to
  # show whether it is a login, registration, failure or other message
  # within authentication generally.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param msg_subtype [String] The type of auth message
  # @param args [Array] All remaining arguments to the method
  # @return [void]
  # @since 0.1.0
  def on_auth_message(ws, msg_subtype, *args)
    raise "Do not use AppInterface directly!"
  end

  # This handler is for player action messages, as chosen by the
  # client-side front end code. This handler will not normally be
  # defined for you. The msg_subtype is normally to show what action
  # is being taken. What entity took the action should be checked via
  # the websocket object, which will be the same as the one passed to
  # on_login or on_open.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param msg_subtype [String] The type of action message
  # @param args [Array] All remaining arguments to the method
  # @return [void]
  # @since 0.1.0
  def on_action_message(ws, msg_subtype, *args)
    raise "Do not use AppInterface directly!"
  end

  # This handler is for messages that do not seem to be authentication
  # or player action messages based on their initial data header. The
  # type of message is chosen by the client-side browser code. This
  # handler will not normally be defined for you and may not be
  # required at all. What user took the action should be checked via
  # the websocket object, which will be the same as the one passed to
  # on_login or on_open.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param args [Array] All remaining arguments to the method
  # @return [void]
  # @since 0.1.0
  def on_message(ws, *args)
    raise "Do not use AppInterface directly!"
  end

  # If you inherit from AuthenticatedApp, this handler will be called
  # when a player has successfully logged in. Later handlers will
  # continue passing the websocket object. This handler lets you
  # associate the websocket with a specific player account. If you
  # override this method, make sure to call super() so that the
  # AuthenticatedApp code can implement methods like
  # {Pixiurge::AuthenticatedApp#username_for_websocket}.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param username [String] The username for the account
  # @return [void]
  # @since 0.1.0
  def on_login(ws, username)
    raise "Do not use AppInterface directly!"
  end

  # This handler dispatches to on_auth_message, on_action_message or
  # on_message, depending on the incoming message type and what
  # handlers the app subtype has defined.  If you override this
  # handler but use the {Pixiurge::AuthenticatedApp}, make sure to
  # call {Pixiurge::AppInterface#on_auth_message} for messages that
  # start with {Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE}.
  #
  # @see #on_action_message
  # @see #on_auth_message
  # @param ws [Websocket] The Ruby-Websocket-Driver websocket object
  # @param data [Hash] Deserialized JSON data sent from the client
  # @since 0.1.0
  def handle_message(ws, data)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has logged into your application. Your
  # handler can do things like create an in-game presence for them, if
  # they should have one.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The new player's registered username
  # @return [void]
  # @since 0.1.0
  def on_player_login(username)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has sent a message from their browser to your application.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The player's registered username
  # @param message_type [String] The type of the message
  # @param args [Array] Arguments sent along with this message
  # @return [void]
  # @since 0.1.0
  def on_player_message(username, message_type, *args)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has logged out of your application.
  # Your handler can do things like remove their in-game presence if
  # they have one.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The new player's registered username
  # @return [void]
  # @since 0.1.0
  def on_player_logout(username)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has reconnected to your application,
  # often by connecting with a new browser. This won't normally
  # require action on your part, but you can react in some way if you
  # wish.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The new player's registered username
  # @return [void]
  # @since 0.1.0
  def on_player_reconnect(username)
    raise "Do not use AppInterface directly!"
  end

  # This method allows you to handle one or more events of your choice
  # using a handler of your choice. For the list of events, see
  # {Pixiurge::AppInterface}. The handler will be called whenever
  # the event occurs, and the block will receive the same arguments
  # that a child method would receive for that event type.
  #
  # @see Pixiurge::AppInterface
  # @param event [String] The name of the event, such as "close" or "player_login"
  # @return [void]
  # @since 0.1.0
  def on_event(event, &block)
    raise "Do not use AppInterface directly!"
  end
end

# {Pixiurge::App} is the parent class of Pixiurge applications
# (games).  By inheriting from this and overriding various handlers,
# your Pixiurge server-side application can respond appropriately to
# the Javascript/Pixi client-side browsers.
#
# An app is used in config.ru to set up web server setup like asset
# directories.  It also defines methods for interacting with players.
# This basic App class is very bare-bones. See
# {Pixiurge::AuthenticatedApp} for a version with accounts and login.
#
# For full documentation of the interface, see
# {Pixiurge::AppInterface}.
#
# @see Pixiurge::AppInterface
# @see Pixiurge::AuthenticatedApp
# @since 0.1.0
class Pixiurge::App
  attr :record_traffic
  attr :debug
  attr :incoming_traffic_logfile
  attr :outgoing_traffic_logfile

  EVENTS = [ "player_login", "player_logout", "player_reconnect", "open", "close", "error", "auth_message", "action_message", "message", "login" ]

  # Constructor for Pixiurge App base class.
  #
  # @param options [Hash] Options to configure app behavior
  # @option options [Boolean] debug Whether to print debug output
  # @option options [Boolean] record_traffic Whether to record incoming and outgoing websocket traffic to logfiles
  # @option options [String] incoming_traffic_logfile Pathname to record incoming websocket traffic
  # @option options [String] outgoing_traffic_logfile Pathname to record outgoing websocket traffic
  # @since 0.1.0
  def initialize(options = { "debug" => false, "record_traffic" => false,
                   "incoming_traffic_logfile" => "log/incoming_traffic.json", "outgoing_traffic_logfile" => "log/outgoing_traffic.json" })
    @debug = options["debug"]
    @record_traffic = options["record_traffic"]
    @incoming_traffic_logfile = options["incoming_traffic_logfile"] || "log/incoming_traffic.json"
    @outgoing_traffic_logfile = options["outgoing_traffic_logfile"] || "log/outgoing_traffic.json"
    @event_handlers = {}
  end

  # The websocket handler for the Pixiurge app.
  #
  # @param ws [Websocket] A Websocket-Driver socket object or object with matching interface
  # @api private
  # @since 0.1.0
  def websocket_handler(ws)
    ws.on :open do |event|
      puts "Socket open" if @debug
      send_event "open", ws
    end

    ws.on :message do |event|
      File.open(@incoming_traffic_logfile, "a") { |f| f.write event.data + "\n" } if @record_traffic
      data = MultiJson.load event.data
      handle_message ws, data
    end

    ws.on :error do |event|
      send_event "error", event.message
    end

    ws.on :close do |event|
      send_event "close", ws, event.code, event.reason
      ws = nil
    end

    # Return async Rack response
    ws
  end

  # This method allows you to handle one or more events of your choice
  # using a handler of your choice. For the list of events, see
  # {Pixiurge::AppInterface}. The handler will be called whenever
  # the event occurs, and the block will receive the same arguments
  # that a child method would receive for that event type.
  #
  # @see Pixiurge::AppInterface
  # @param event [String] The name of the event, such as "close" or "player_login"
  # @return [void]
  # @since 0.1.0
  def on_event(event, &block)
    raise("Can't subscribe to unrecognized event #{event.inspect}! Only #{EVENTS.inspect}!") unless EVENTS.include?(event)
    @event_handlers[event] ||= []
    @event_handlers[event].push(block)
  end

  private
  def send_event(event_name, *args)
    if self.respond_to?("on_" + event_name.to_s)
      self.send("on_" + event_name.to_s, *args)
    end
    (@event_handlers[event_name] || []).each do |handler|
      handler.call(*args)
    end
    nil
  end
  public

  # This handler dispatches to on_auth_message, on_action_message or
  # on_message, depending on the incoming message type and what
  # handlers the app subtype has defined.  If you override this
  # handler but use the {Pixiurge::AuthenticatedApp}, make sure to
  # call {Pixiurge::App#on_auth_message} for messages that start with
  # {Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE}.
  #
  # @see #on_action_message
  # @see #on_auth_message
  # @param ws [Websocket] The Ruby-Websocket-Driver websocket object
  # @param data [Hash] Deserialized JSON data sent from the client
  # @since 0.1.0
  def handle_message(ws, data)
    if data[0] == Pixiurge::Protocol::Incoming::AUTH_MSG_TYPE
      return send_event "auth_message", ws, data[1], *data[2..-1]
    end
    if data[0] == Pixiurge::Protocol::Incoming::ACTION_MSG_TYPE
      return send_event "action_message", ws, data[1], *data[2..-1]
    end
    return send_event "message", ws, data
  end

  private

  def websocket_send(socket, *args)
    json_data = MultiJson.dump(args)
    if record_traffic
      File.open(@outgoing_traffic_logfile, "a") { |f| f.write json_data + "\n" } if @record_traffic
    end
    socket.send json_data
  end

  public

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
        ws = Faye::WebSocket.new(env)
        return websocket_handler(ws).rack_response
      else
        if @root_dir && static_files.include?(env["PATH_INFO"])
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
