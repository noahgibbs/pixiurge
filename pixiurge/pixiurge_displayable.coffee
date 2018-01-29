# Here's the parent class for Displayables
class Pixiurge.Displayable
  constructor: (data_hash) ->
    @parent_container = data_hash.parent_container
    @displayable_name = data_hash.displayable_name
    @displayable_data = data_hash.displayable_data
    @pixi_display = data_hash.pixi_display

  show: () ->

  destroy: () ->
    throw("Implement me!")

  sendDisplayEvent: (eventName, eventData) ->
    @pixi_display.sendDisplayEvent eventName, @displayable_name, eventData
