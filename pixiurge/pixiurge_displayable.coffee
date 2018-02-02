# Here's the parent class for Displayables
class Pixiurge.Displayable
  constructor: (dataHash) ->
    @parentContainer = dataHash.parentContainer
    @displayableName = dataHash.displayableName
    @displayableData = dataHash.displayableData
    @pixiDisplay = dataHash.pixiDisplay

  show: () ->

  destroy: () ->
    throw("Implement me!")

  sendDisplayEvent: (eventName, eventData) ->
    @pixiDisplay.sendDisplayEvent eventName, @displayableName, eventData
