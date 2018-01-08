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
end
