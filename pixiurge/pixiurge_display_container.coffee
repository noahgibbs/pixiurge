class Pixiurge.DisplayContainer extends Pixiurge.Displayable
  constructor: (pixi_display, parent_container, item_name, item_data) ->
    super(parent_container, item_name, item_data)

    contents_messages = item_data.contents
    @pixi_container = new PIXI.Container()
    parent_container.addChild @pixi_container

    # This won't instantly load everything. Lots of Displayable types put stuff into a loader and load over time.
    @contents = (pixi_display.createDisplayableFromMessages(@pixi_container, msgs[0], msgs[1]) for msgs in contents_messages)
