# Here's the parent class for Displayables
class Pixiurge.Displayable
  constructor: (@parent_container, @item_name, @item_data) ->

  show: () ->

  destroy: () ->
    throw("Implement me!")
