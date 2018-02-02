class Pixiurge.DisplayContainer extends Pixiurge.Displayable
  constructor: (dataHash) ->
    super(dataHash)

    contentsMessages = @displayableData.contents
    @pixiContainer = new PIXI.Container()
    @parentContainer.addChild @pixiContainer

    dispData = @displayableData.displayable
    if dispData.x? && dispData.x && dispData.y? && dispData.y
      @pixiContainer.x = dispData.x * dispData.location_block_width
      @pixiContainer.y = dispData.y * dispData.location_block_height

    # This won't instantly load everything. Lots of Displayable types put stuff into a loader and load over time.
    @contents = (@pixiDisplay.createDisplayableFromMessages(@pixiContainer, msgs[0].name, msgs[0]) for msgs in contentsMessages)
