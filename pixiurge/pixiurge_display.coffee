# Pixi display for Pixiurge. Mostly this is a message handler to
# dispatch to more specific Pixi drawing classes.

messageMap = {
  "display_init": "initMessage",
  "display_show": "showDisplayable",
  "display_destroy": "destroyDisplayable",
  "display_destroy_all": "destroyAllDisplayables",
  "display_move": "moveStackTo",
  "display_pan": "panToPixel",
}

class Pixiurge.Display
  constructor: (@pixiurge, options = {}) ->
    @displayables = {}
    @display_event_handlers = {}

    @container_spec = options["container"] || "body"
    @item_klasses = {
      particle_source: Pixiurge.ParticleSource,
      tile_animated_sprite: Pixiurge.TileAnimatedSprite,
      tmx: Pixiurge.TmxMap,
      container: Pixiurge.DisplayContainer,
    }

  setup: () ->

  pixi_setup: () ->
    @exposure = { x: @display_width / 2, y: @display_height / 2, width: @display_width, height: @display_height }

    @pixi_app = new PIXI.Application(width: @display_width, height: @display_height)
    @stage = @pixi_app.stage
    $(@container_spec).append(@pixi_app.view)

    # Later figure out Z-ordering: http://pixijs.io/examples/#/layers/zorder.js
    @layers_container = new PIXI.Container
    @stage.addChild @layers_container
    @fringe_container = new PIXI.Container
    @fringe_container.z = 0
    @layers_container.addChild @fringe_container

  message: (msgName, argArray) ->
    handler = messageMap[msgName]
    unless handler? && this[handler]
      console.warn "Couldn't handle message type #{msgName}!"
      return
    this[handler](argArray...)

  initMessage: (data) ->
    console.log "Pixiurge Init Message", data
    @display_width = data.width
    @display_height = data.height
    @ms_per_tick = data.ms_per_tick
    @pixi_setup()

  panToPixel: (x, y) ->
    @exposure = { x: x, y: y, width: @display_width, height: @display_height }
    left_x = @exposure.x - (@exposure.width - @display_width / 2)
    upper_y = @exposure.y - (@exposure.height - @display_height / 2)
    @layers_container.x = -left_x
    @layers_container.y = -upper_y

  showDisplayable: (item_name, item_data) ->
    if @displayables[item_name]
      console.log "Item name '#{item_name}' already exists!"
      return
    displayable = @createDisplayableFromMessages(@layers_container, item_name, item_data)
    unless displayable? && displayable
      console.log "Got back undefined or false displayable from creation: #{displayable}", displayable
      return
    @displayables[item_name] = displayable

  createDisplayableFromMessages: (parent_container, item_name, item_data) ->
    item_type = item_data.type
    klass = @item_klasses[item_type]
    unless klass?
      klasses = (key for key, val of @item_klasses)
      console.log "Couldn't find a class for item type: #{item_type}! Legal types:", klasses
      return undefined
    new klass(pixi_display: this, parent_container: parent_container, displayable_name: item_name, displayable_data: item_data)

  # This destroys this Displayable - it won't be referenced by name
  # again, ever (unless you recreate it.)
  destroyDisplayable: (item_name) ->
    if @displayables[item_name]
      @displayables[item_name].destroy()
      @displayables.delete(item_name)

  # This destroys all Displayables and invalidates any hints or preloads
  destroyAllDisplayables: () ->
    for item_name, displayable of @displayables
      displayable.destroy()
    @displayables = {}

  onDisplayEvent: (event, object_name, handler) ->
    unless @display_event_handlers[event]?
      @display_event_handlers[event] = { any: [] }
    @display_event_handlers[event].any.push(handler)
    unless @display_event_handlers[event][object_name]?
      @display_event_handlers[event][object_name] = []
    @display_event_handlers[event][object_name].push(handler)

  sendDisplayEvent: (event, object_name, data) ->
    unless @display_event_handlers[event]?
      return
    for handler in @display_event_handlers[event].any
      handler(event, object_name, data)
    for handler in (@display_event_handlers[object_name] || [])
      handler(event, object_name, data)
