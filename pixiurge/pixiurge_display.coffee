# Pixi display for Pixiurge. Mostly this is a message handler to
# dispatch to more specific Pixi drawing classes.

messageMap = {
  "display_init": "initMessage",
  "display_show": "showDisplayable",
  "display_destroy": "destroyDisplayable",
  "display_destroy_all": "destroyAllDisplayables",
  "display_pan": "panToPixel",
}

class Pixiurge.Display
  constructor: (@pixiurge, options = {}) ->
    @pixiurge.display = this
    @displayables = {}
    @displayEventHandlers = {}

    @containerSpec = options["container"] || "body"
    @pixiOptions = options["pixiOptions"] || {}
    @itemKlasses = {
      particle_source: Pixiurge.ParticleSource,
      tile_animated_sprite: Pixiurge.TileAnimatedSprite,
      tmx: Pixiurge.TmxMap,
      container: Pixiurge.DisplayContainer,
    }
    @loader = new Pixiurge.Loader()

  setup: () ->

  pixiSetup: () ->
    @exposure = { x: @displayWidth / 2, y: @displayHeight / 2, width: @displayWidth, height: @displayHeight }

    pixiAppOptions = { width: @displayWidth, height: @displayHeight }
    pixiAppOptions[key] = value for key, value of @pixiOptions
    @pixiApp = new PIXI.Application(pixiAppOptions)
    @stage = @pixiApp.stage
    $(@containerSpec).append(@pixiApp.view)

    # Later figure out Z-ordering: http://pixijs.io/examples/#/layers/zorder.js
    @layersContainer = new PIXI.Container
    @stage.addChild @layersContainer
    @fringeContainer = new PIXI.Container
    @fringeContainer.z = 0
    @layersContainer.addChild @fringeContainer

  message: (msgName, argArray) ->
    handler = messageMap[msgName]
    unless handler? && this[handler]
      console.warn "Couldn't handle message type #{msgName}!"
      return
    this[handler](argArray...)

  initMessage: (data) ->
    console.log "Pixiurge Init Message", data
    @displayWidth = data.width
    @displayHeight = data.height
    @msPerTick = data.ms_per_tick
    @pixiSetup()

  panToPixel: (x, y) ->
    @exposure = { x: x, y: y, width: @displayWidth, height: @displayHeight }
    leftX = @exposure.x - (@exposure.width - @displayWidth / 2)
    upperY = @exposure.y - (@exposure.height - @displayHeight / 2)
    @layersContainer.x = -leftX
    @layersContainer.y = -upperY

  showDisplayable: (itemName, itemData) ->
    if @displayables[itemName]
      console.log "Item name '#{itemName}' already exists!"
      return
    displayable = @createDisplayableFromMessages(@layersContainer, itemName, itemData)
    unless displayable? && displayable
      console.log "Got back undefined or false displayable from creation: #{displayable}", displayable
      return
    @displayables[itemName] = displayable

  createDisplayableFromMessages: (parentContainer, itemName, itemData) ->
    itemType = itemData.type
    klass = @itemKlasses[itemType]
    unless klass?
      klasses = (key for key, val of @itemKlasses)
      console.log "Couldn't find a class for item type: #{itemType}! Legal types:", klasses
      return undefined
    new klass(pixiDisplay: this, parentContainer: parentContainer, displayableName: itemName, displayableData: itemData)

  # This destroys this Displayable - it won't be referenced by name
  # again, ever (unless you recreate it.)
  destroyDisplayable: (itemName) ->
    if @displayables[itemName]
      @displayables[itemName].destroy()
      @displayables.delete(itemName)

  # This destroys all Displayables and invalidates any hints or preloads
  destroyAllDisplayables: () ->
    for itemName, displayable of @displayables
      displayable.destroy()
    @displayables = {}

  onDisplayEvent: (event, objectName, handler) ->
    unless @displayEventHandlers[event]?
      @displayEventHandlers[event] = { any: [] }
    @displayEventHandlers[event].any.push(handler)
    unless @displayEventHandlers[event][objectName]?
      @displayEventHandlers[event][objectName] = []
    @displayEventHandlers[event][objectName].push(handler)

  sendDisplayEvent: (event, objectName, data) ->
    unless @displayEventHandlers[event]?
      return
    for handler in @displayEventHandlers[event].any
      handler(event, objectName, data)
    for handler in (@displayEventHandlers[objectName] || [])
      handler(event, objectName, data)
