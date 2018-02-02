class Pixiurge.DisplayContainer extends Pixiurge.Displayable
  constructor: (dataHash) ->
    super(dataHash)

    contentsMessages = @displayable_data.contents
    @pixi_container = new PIXI.Container()
    @parent_container.addChild @pixi_container

    dispData = @displayable_data.displayable
    if dispData.x? && dispData.x && dispData.y? && dispData.y
      @pixi_container.x = dispData.x * dispData.location_block_width
      @pixi_container.y = dispData.y * dispData.location_block_height

    # This won't instantly load everything. Lots of Displayable types put stuff into a loader and load over time.
    @contents = (@pixi_display.createDisplayableFromMessages(@pixi_container, msgs[0].name, msgs[0]) for msgs in contentsMessages)
