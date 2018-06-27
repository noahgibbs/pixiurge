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
# * {#on_player_action} - an action message has been received from a logged-in player via their browser
# * {#on_player_reconnect} - a player has re-logged in, often from a new browser session
#
# Next are the message handlers that your app can define for the
# low-level message and socket interface. Keep in mind that
# higher-level functionality with AuthenticatedApp may depend on
# existing methods for these, so you should call super as appropriate
# if you override the methods. This is not a problem if you subscribe
# to events instead of overriding handler methods, which can be a good
# reason to use {#on_event} for these.
#
# * {#on_open} - message handler for a newly-opened connection
# * {#on_close} - connection has been closed
# * {#on_error} - an error has occurred in the websocket layer
# * {#on_message} - generic low-level message handler for messages not handled by the app
# * {#on_login} - called when a user successfully logs in using built-in authentication (AuthenticatedApp only)
#
# And finally there's a low-level websocket message handler you can
# override, but it doesn't send events via on_event or handle them with on_message_type:
#
# * {#handle_message} - very low-level message handler, only use it if you're comfortable reading the source code
#
# Some of these handlers may already be defined if you use AuthenticatedApp,
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

  # This handler is for messages that are not automatically handled by
  # your application (e.g. non-auth messages for an AuthenticatedApp.)
  # The message content is sent by the client-side browser code. What
  # user took the action should be checked via the websocket object,
  # which will be the same as the one passed to on_login or on_open.
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

  # This handler can be enhanced or overridden by various App
  # subtypes, and will normally dispatch to on_message or other
  # handlers if it can't fully handle a given message itself.  If you
  # want to be sure to catch every message for some reason, this can
  # be the method to override to do it. This method has no equivalent
  # event for {#on_event}.
  #
  # @param ws [Websocket] The Ruby-Websocket-Driver websocket object
  # @param data [Hash] Deserialized JSON data sent from the client
  # @since 0.1.0
  def handle_message(ws, data)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has logged into your application. Your
  # handler can reflect their logged-in state in their visible
  # presence, if they have one.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The new player's registered username
  # @return [void]
  # @since 0.1.0
  def on_player_login(username)
    raise "Do not use AppInterface directly!"
  end

  # This event means a player has logged into your application and has
  # no current Demiurge item to represent them. Your handler should
  # create a Demiurge item to represent them.
  #
  # @see AuthenticatedApp#websocket_for_username
  # @param username [String] The new player's registered username
  # @return [void]
  # @since 0.1.0
  def on_player_create_body(username)
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
  def on_player_action(username, action_name, *args)
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
  # @yield Your handler for the event in question, which takes event-dependent arguments
  # @yieldreturn [void]
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
  # Whether the app is currently recording Websocket traffic to logfiles; useful for development, bad in production
  attr_reader :record_traffic
  # Whether to print debugging messages - can be set to nil/false, or to an Integer
  attr_reader :debug
  # Path to logfile for incoming Websocket messages
  attr_reader :incoming_traffic_logfile
  # Path to logfile for outgoing Websocket messages
  attr_reader :outgoing_traffic_logfile

  EVENTS = [ "player_login", "player_logout", "player_create_body", "player_action", "player_reconnect", "open", "close", "error", "message", "login" ]

  # Legal options to pass to Pixiurge::App.new
  INIT_OPTIONS = [ :debug, :record_traffic, :incoming_traffic_logfile, :outgoing_traffic_logfile ]

  # Constructor for Pixiurge App base class.
  #
  # Debugging options:
  #
  # * :debug - whether to print debugging messages
  # * :record_traffic - whether to write network messages to a JSON logfile
  # * :incoming_traffic_logfile - the logfile for client-to-server traffic
  # * :outgoing_traffic_logfile - the logfile for server-to-client traffic
  #
  # @param options [Hash] Options to configure app behavior
  # @option options [Boolean] :debug Whether to print debug output
  # @option options [Boolean] :record_traffic Whether to record incoming and outgoing websocket traffic to logfiles
  # @option options [String] :incoming_traffic_logfile Pathname to record incoming websocket traffic
  # @option options [String] :outgoing_traffic_logfile Pathname to record outgoing websocket traffic
  # @since 0.1.0
  def initialize(options = { :debug => false, :record_traffic => false,
                   :incoming_traffic_logfile => "log/incoming_traffic.json", :outgoing_traffic_logfile => "log/outgoing_traffic.json" })
    illegal_options = options.keys - INIT_OPTIONS
    raise("Illegal options passed to Pixiurge::App#new: {illegal_options.inspect}!") unless illegal_options.empty?
    @debug = options[:debug]
    @record_traffic = options[:record_traffic]
    @incoming_traffic_logfile = options[:incoming_traffic_logfile] || "log/incoming_traffic.json"
    @outgoing_traffic_logfile = options[:outgoing_traffic_logfile] || "log/outgoing_traffic.json"
    @event_handlers = {}
    @message_handlers = {}
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
  # @yield Your handler for the event in question, which takes event-dependent arguments
  # @yieldreturn [void]
  # @return [void]
  # @since 0.1.0
  def on_event(event, &block)
    raise("Can't subscribe to unrecognized event #{event.inspect}! Only #{EVENTS.inspect}!") unless EVENTS.include?(event)
    @event_handlers[event] ||= []
    @event_handlers[event].push(block)
  end

  # This method declares a handler for a specific message type. Each
  # message type may only have a single handler. Ordinarily a
  # particular file, class or splinter will declare multiple message
  # types and multiple handlers for inclusion, and handle only its own
  # types - an example of this method is Authentication, which
  # declares a number of authentication-specific messages and ignores
  # all others.
  #
  # @see #on_message, #handle_message
  # @param message_name [String] The message type to handle
  # @yield The handler for this message type
  # @return [void]
  # @since 0.2.0
  def on_message_type(message_name, &block)
    raise MessageTypeError.new("Message type '#{message_name}' already has a handler!") if @message_handlers[message_name]
    @message_handlers[message_name] = block
    nil
  end

  private
  # Sends an event such as {#on_event} would receive. This checks for
  # both inherited handler methods and on_event subscriptions.
  def send_event(event_name, *args)
    # Call the inherited event handler first, if any
    if self.respond_to?("on_" + event_name.to_s)
      self.send("on_" + event_name.to_s, *args)
    end
    (@event_handlers[event_name] || []).each do |handler|
      handler.call(*args)
    end
    nil
  end
  public

  # This handler can be used to handle certain messages before
  # dispatching them to one or more other events or handlers.
  #
  # @param ws [Websocket] The Ruby-Websocket-Driver websocket object
  # @param data [Object] Deserialized JSON data sent from the client
  # @since 0.1.0
  def handle_message(ws, data)
    msg_type = data[0]

    if @message_handlers[msg_type]
      return @message_handlers[msg_type].call(ws, data)
    end

    return send_event "message", ws, data
  end

  private

  # Send with traffic logging
  def websocket_send(socket, *args)
    json_data = MultiJson.dump(args)
    if record_traffic
      File.open(@outgoing_traffic_logfile, "a") { |f| f.write json_data + "\n" } if @record_traffic
    end
    socket.send json_data
  end
end
