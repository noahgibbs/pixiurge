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

    @container_spec = options["container"] || "body"
    @item_klasses = {
      particle_source: Pixiurge.ParticleSource,
      tile_animated_sprite: Pixiurge.TileAnimatedSprite,
      tmx: Pixiurge.TmxMap,
    }

  setup: () ->

  pixi_setup: () ->
    @exposure = { x: @display_width / 2, y: @display_height / 2, width: @display_width, height: @display_height }

    @pixi_app = new PIXI.Application(width: @display_width, height: @display_height)
    @stage = @pixi_app.stage
    $(@container_spec).append(@pixi_app.view)

    #createjs.Ticker.timingMode = createjs.Ticker.RAF
    #createjs.Ticker.addEventListener "tick", (event) =>
    #  @stage.update event

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

  showDisplayable: (item_name, item_data) ->
    if @displayables[item_name]
      console.log "Item name '#{item_name}' already exists!"
      return
    item_type = item_data.type
    klass = @klass_for_type(item_type)
    unless klass?
      console.log "Couldn't find a class for item type: #{item_type}!", item_type, @item_klasses
      return
    @displayables[item_name] = new klass(this, item_name, item_data)

  # This destroys this Displayable - it won't be referenced by name again, ever
  destroyDisplayable: (item_name) ->
    if @displayables[item_name]
      @displayables[item_name].destroy()
      @displayables.delete(item_name)

  # This destroys all Displayables and invalidates any hints or preloads
  destroyAllDisplayables: () ->
    for item_name, displayable of @displayables
      displayable.destroy()
    @displayables = {}

  klass_for_type: (item_type) ->
    @item_klasses[item_type]


  #panToPixel: (new_exp_x, new_exp_y, options) ->
  #  duration = options.duration || 1.0
  #  createjs.Tween.get(@exposure)
  #    .to({x: new_exp_x, y: new_exp_y}, duration * 1000.0, createjs.Ease.linear)
  #    .addEventListener "change", () =>
  #      for name, stack of @spritestacks
  #        stack.handleExposure()
  #    .call (tween) =>
  #      @exposure.x = new_exp_x
  #      @exposure.y = new_exp_y
  #
  #textOverStack: (stack, text, options = {}) ->
  #  stack = @spritestacks[stack]
  #  duration = options.duration || 5.0
  #  text_x = stack.x - @exposure.x + @display_width / 2
  #  text_y = stack.y - @exposure.y + @display_height / 2 - 32 # Add a fudge factor for ManaSource humanoids having a weird registration point for right now...
  #
  #  new DCJS.CreatejsDisplay.TextAnim(@stage, text, { x: text_x, y: text_y, color: options.color, font: options.font, duration: options.duration || 5.0 } )
