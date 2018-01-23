# Here's the parent class for Displayables
class Pixiurge.Displayable
  constructor: (@pixi_display, @item_name, @item_data) ->

  show: () ->

  destroy: () ->
    throw("Implement me!")
