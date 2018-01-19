# Pixi display for Pixiurge. Mostly this is a message handler to
# dispatch to more specific Pixi drawing classes.

messageMap = {
  "displayInit": "initMessage",
  "displayNewSpriteSheet": "newSpriteSheet",
  "displayNewSpriteStack": "newSpriteStack",
  "displayHideSpriteSheet": "hideSpriteSheet",
  "displayHideSpriteStack": "hideSpriteStack",
  "displayStartAnimation": "startAnimation",
  "displayMoveStackTo": "moveStackTo",
  "displayTeleportStackTo": "teleportStackTo",
  "displayMoveStackToPixel": "moveStackToPixel",
  "displayTeleportStackToPixel": "teleportStackToPixel",
  "displayInstantPanToPixel": "instantPanToPixel",
  "displayPanToPixel": "panToPixel",
  "displayTextAnimOverStack": "textOverStack",
}

class Pixiurge.Display
  constructor: (@pixiurge, options = {}) ->
    @spritesheets = {}
    @spritestacks = {}

    @container_spec = options["container"] || "body"

  setup: () ->

  pixi_setup: () ->
    @exposure = { x: @display_width / 2, y: @display_height / 2, width: @display_width, height: @display_height }

    @pixi_app = new PIXI.Application(width: @display_width, height: @display_height)
    @stage = @pixi_app.stage
    $(@container_spec).append(@pixi_app.view)
    @layer_container = new PIXI.Container
    @stage.addChild(@layer_container)
    @fringe_container = new PIXI.Container
    @fringe_container.z = 0.0
    @layer_container.addChild(@fringe_container)

    #createjs.Ticker.timingMode = createjs.Ticker.RAF
    #createjs.Ticker.addEventListener "tick", (event) =>
    #  @stage.update event

  #add_to_layer_container: (container) ->
  #  @layer_container.addChild(container)
  #  @sort_layer_container()   # TODO: just add this one child in sorted order
  #
  #add_to_fringe_container: (item) ->
  #  @fringe_container.addChild(item)
  #  @sort_fringe_container()   # TODO: just add this one child in sorted order
  #
  #sort_layer_container: () ->
  #  cur = this
  #  sf = (obj1, obj2) -> cur.spaceship(obj1.z, obj2.z)
  #  @layer_container.sortChildren(sf)
  #
  #sort_fringe_container: () ->
  #  cur = this
  #  sf = (obj1, obj2, options) ->
  #    y1 = if obj1.y then obj1.y else 0.0
  #    y2 = if obj2.y then obj2.y else 0.0
  #    if y1 == y2 && obj1.stack_y? && obj2.stack_y?
  #      cur.spaceship(obj1.stack_y, obj2.stack_y)
  #    else
  #      cur.spaceship(y1, y2)
  #  @fringe_container.sortChildren(sf)
  #
  ## TODO: Figure out how to expose CreateJS events:
  ##   complete  (everything complete)
  ##   error     (error while loading)
  ##   progress  (total queue progress)
  ##   fileload  (one file loaded)
  ##   fileprogress  (progress in single file)
  #on_load_update: (handler) ->
  #  @load_handler = handler
  #  DCJS.CreatejsDisplay.loader.setHandler handler

  message: (msgName, argArray) ->
    handler = messageMap[msgName]
    unless handler?
      console.warn "Couldn't handle message type #{msgName}!"
      return
    this[handler](argArray...)

  initMessage: (data) ->
    console.log "Pixiurge Init Message", data
    @display_width = data.width
    @display_height = data.height
    @ms_per_tick = data.ms_per_tick
    @pixi_setup()

  ## This method takes the following keys to its argument:
  ##    name: the spritesheet name
  ##    images: an array of images
  ##    tilewidth: the width of each tile
  ##    tileheight: the height of each tile
  ##    animations: an object of animation names mapped to DCJS animation specs (see animate methods)
  ##
  ## Here's an example (slightly outdated in format?):
  ## {
  ##   "name" => "test_humanoid_spritesheet",
  ##   "tilewidth" => 64,
  ##   "tileheight" => 64,
  ##   "animations" => { "stand" => 1, "sit" => [2, 5], "jumpsit" => [6, 9, "sit", 200], "kersquibble" => {} },
  ##   "images" => [
  ##     {
  ##       "firstgid" => 1,
  ##       "image" => "/sprites/skeleton_walkcycle.png",
  ##       "imagewidth" => 576,
  ##       "image_height" => 256
  ##     }
  ## }
  ##
  #newSpriteSheet: (data) ->
  #  @spritesheets[data.name] = new DCJS.CreatejsDisplay.CreatejsSpriteSheet(data)
  #
  #hideSpriteSheet: (data) ->
  #  @spritesheets[data.name].detach()
  #  delete @spritesheets[data.name]
  #
  ## Keys in data arg:
  ##     name: name of spritestack
  ##     spritesheet: name of spritesheet
  ##     width:
  ##     height:
  ##     layers: { name: "", visible: true, opacity: 1.0, data: [ [1, 2, 3], [4, 5, 6], [7, 8, 9] ] }
  #newSpriteStack: (data) ->
  #  sheet = @spritesheets[data.spritesheet]
  #  unless sheet?
  #    console.warn "Can't find spritesheet #{data.spritesheet} for sprite #{data.name}!"
  #    return
  #
  #  stack = new DCJS.CreatejsDisplay.CreatejsSpriteStack(this, sheet, data)
  #  @spritestacks[data.name] = stack
  #
  #hideSpriteStack: (data) ->
  #  childIndex = 0
  #  child = @layer_container.getChildAt(0)
  #  while child?
  #    if child.stack_name == data.name
  #      @layer_container.removeChildAt(childIndex)
  #    else
  #      childIndex++
  #    child = @layer_container.getChildAt(childIndex)
  #  childIndex = 0
  #  child = @fringe_container.getChildAt(0)
  #  while child?
  #    if child.stack_name == data.name
  #      @fringe_container.removeChildAt(childIndex)
  #    else
  #      childIndex++;
  #    child = @fringe_container.getChildAt(childIndex)
  #  @spritestacks[data.name].detach()
  #  delete @spritestacks[data.name]
  #
  #startAnimation: (data) ->
  #  stack = @spritestacks[data.stack]
  #  stack.animateTile data.layer, data.h, data.w, data.anim
  #
  #teleportStackTo: (stack, x, y, options) ->
  #  stack = @spritestacks[stack]
  #  stack.teleportTo x, y, duration: options.duration || 1.0
  #
  #moveStackTo: (stack, x, y, options) ->
  #  stack = @spritestacks[stack]
  #  stack.moveTo x, y, duration: options.duration || 1.0
  #
  #teleportStackToPixel: (stack, x, y, options) ->
  #  stack = @spritestacks[stack]
  #  stack.teleportToPixel x, y
  #
  #moveStackToPixel: (stack, x, y, options) ->
  #  stack = @spritestacks[stack]
  #  stack.moveToPixel x, y, duration: options.duration || 1.0
  #
  #instantPanToPixel: (x, y) ->
  #  @exposure = { x: x, y: y, width: @display_width, height: @display_height }
  #  for name, stack of @spritestacks
  #    stack.handleExposure()
  #
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
  #
  #spaceship: (o1, o2) ->
  #  if o1 > o2
  #    1
  #  else if o2 > o1
  #    -1
  #  else
  #    0
