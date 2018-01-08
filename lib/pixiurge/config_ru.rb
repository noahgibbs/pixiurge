require "faye/websocket"
require "rack/coffee"

# No luck with Puma - for now, hardcode using Thin
# TODO: move this into Pixiurge.rack_builder
Faye::WebSocket.load_adapter('thin')

require "pixiurge"

