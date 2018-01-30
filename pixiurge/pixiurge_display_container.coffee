class Pixiurge.DisplayContainer extends Pixiurge.Displayable
  constructor: (data_hash) ->
    super(data_hash)

    contents_messages = @displayable_data.contents
    @pixi_container = new PIXI.Container()
    @parent_container.addChild @pixi_container

    # This won't instantly load everything. Lots of Displayable types put stuff into a loader and load over time.
    @contents = (@pixi_display.createDisplayableFromMessages(@pixi_container, msgs[0].name, msgs[0]) for msgs in contents_messages)
