# Here's the parent class for Displayables
class Pixiurge.Displayable
  constructor: (dataHash) ->
    @parent_container = dataHash.parent_container
    @displayable_name = dataHash.displayable_name
    @displayable_data = dataHash.displayable_data
    @pixi_display = dataHash.pixi_display

  show: () ->

  destroy: () ->
    throw("Implement me!")

  sendDisplayEvent: (eventName, eventData) ->
    @pixi_display.sendDisplayEvent eventName, @displayable_name, eventData
