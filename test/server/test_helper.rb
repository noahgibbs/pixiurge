ENV['RACK_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "pixiurge"

require "minitest"
require "rack/test"
require "multi_json"

# This specifically mocks the interface of faye/websocket-driver-ruby
# (https://github.com/faye/websocket-driver-ruby).
class MockWebSocket
  EVENT_TYPES = [ :open, :message, :error, :close ]

  attr_reader :sent_data

  def initialize
    @handlers = {}
    @sent_data = []
  end

  def on(action, &block)
    raise("Illegal fake WebSocket event type: #{action.inspect}!") unless EVENT_TYPES.include?(action)
    @handlers[action] = block
  end

  def send(data)
    raise("Sent data is not a string!") unless data.is_a?(String)
    @sent_data.push data
  end

  def open
    @handlers[:open] && @handlers[:open].call(WebSocket::Driver::OpenEvent.new())
  end

  def error(message = "Generic error!")
    @handlers[:error] && @handlers[:error].call(WebSocket::Driver::ErrorEvent.new(message))
  end

  def close(code = 1000, reason = "Normal exit")
    @handlers[:close] && @handlers[:close].call(WebSocket::Driver::CloseEvent.new(code, reason))
  end

  # This is for a text message. Binary will have an array of Integers for data.
  def message(data)
    raise("Message should be a String!") unless data.is_a?(String)
    @handlers[:message] && @handlers[:message].call(WebSocket::Driver::MessageEvent.new(data))
  end

  # This is for a text message. Binary will have an array of Integers for data.
  def json_message(data)
    @handlers[:message] && @handlers[:message].call(WebSocket::Driver::MessageEvent.new(MultiJson.dump(data)))
  end

  def parsed_sent_data
    @sent_data.map { |d| MultiJson.load d }
  end
end

# For WebSocket tests, we'll want to fake the whole WebSocket
# apparatus. The easiest way to do that is to skip the Rack Hijack
# interface entirely and just pass in a fake Faye WebSocket.
#
# That requires a reference to the Pixiurge::App, which is different
# from the Rack::Builder app. So instead of "app" like Rack-Test uses,
# we'll use a different app setup. We won't normally want to serve
# static assets (and it's annoying to do both since it requires
# mocking Rack and the websocket bits separately) so we'll normally
# set up only (fake) WebSockets, not WebSockets and Rack.
class WebSocketTest < Minitest::Test
  #include Rack::Test::Methods
  attr_reader :pixi_app

  def setup
    @pixi_app = nil
    @ws = nil
  end

  def get_pixi_app
    return @pixi_app if @pixi_app

    @pixi_app = self.pixi_app
    @ws = MockWebSocket.new
    @pixi_app.websocket_handler(ws)

    @pixi_app
  end

  def ws
    return @ws if @ws
    get_pixi_app
    @ws
  end
end

require 'minitest/autorun'
