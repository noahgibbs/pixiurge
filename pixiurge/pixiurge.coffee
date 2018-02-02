# The top-level Pixiurge library sets up message handling for default graphical display and
# whatever the game wants to handle.

class window.Pixiurge
  constructor: () ->
    @messageHandlers = []
  setTransport: (transport) ->
    @transport = transport
  setMessageHandler: (prefix, handler) ->
    @messageHandlers.push [prefix, handler]

  getTransport: () -> @transport
  setup: (options = {}) ->
    pixiurgeObj = this
    @transport.onMessage (msgName, args) -> pixiurgeObj.gotTransportCall(msgName, args)
    @transport.setup()
    for items in @messageHandlers
      handler = items[1]
      if handler.setup?
        handler.setup()

  gotTransportCall: (msgName, args) ->
    for items in @messageHandlers
      prefix = items[0]
      handler = items[1]
      if prefix == "" || msgName.slice(0, prefix.length) == prefix
        return handler.message(msgName, args)

    # TODO: send back a warning to the server side?
    console.warn "Unknown message name: #{msgName}, args: #{args}"

# This is an example message-handling parent class
class Pixiurge.Simulation
  constructor: (@dcjs) ->
  setup: () ->
  message: (messageType, argArray) ->
    if messageType == "simNotification"
      @notification(argArray[0])
    else
      console.warn "Unknown simulation message type: #{messageType}!"
  notification: (data) ->
    console.log "Implement a Pixiurge.Simulation subclass to do something with your notifications!"
