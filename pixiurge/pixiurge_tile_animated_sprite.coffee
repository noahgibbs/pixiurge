# This sprite accepts and loads multiple tilemaps and handles
# appropriate frames and animation timing. The supplied information is
# used to create textures for a PIXI.extras.AnimatedSprite.
class Pixiurge.TileAnimatedSprite extends Pixiurge.Displayable

  # Every Pixiurge Displayable takes a Pixiurge Display object, an
  # item name and a hash of item data, but each Displayable subtype
  # decides on the format of its own item data. The TileAnimatedSprite
  # uses the following format:

  # params: {
  #     tilesets: [
  #       {
  #         name: "name1",
  #         url: "https://first_url.com/path",
  #         tile_width: 32,
  #         tile_height: 32,
  #       },
  #       {
  #         name: "name2",
  #         url: "https://second_url.com/path",
  #         tile_width: 32,
  #         tile_height: 32,
  #         first_frame_id: 37,   # Frame ID of the first tile in this tileset
  #         spacing: 3, # Optional field, default 0
  #         margin: 2,  # Optional field, default 0
  #         reg_x: 16,  # Optional field for anchor/registration x coord, default 0
  #         reg_y: 16,  # Optional field for anchor/registration y coord, default 0
  #       }
  #     ],
  #     animations: {
  #       funny_walk: { frames: [ 1, 2, 3, 4, 5 ], after: "loop" },
  #       second_anim: { frames: [ 7, 2, 4, 1, 6 ], after: "funny_walk" },
  #       third_anim: { frames: [
  #         { tileset: "name1", x: 0, y: 0, width: 32, height: 32, duration: 100 },
  #         { frame_id: 7, duration: 150 },
  #         { tileset: "name2", x: 32, y: 96, width: 32, height: 32, duration: 50 },
  #         7,
  #         15
  #       ], after: "loop" },
  #       fourth_anim: {
  #         frames: [1, 7, 4, 19], after: [
  #           { name: "funny_walk", "chance" 1.0 },
  #           { name: "second_anim", chance: 4 },
  #           { name: "third_anim" } ]
  #       }
  #     }
  #     animation: "funny_walk"
  # }

  # For tilesets, the url property is where to load the tileset
  # from. The tile_width, tile_height, spacing and margin define the
  # size and location of the frames within a tileset. The
  # first_frame_id defaults to 1 for the first tileset and gives the
  # frame ID (number) for the very first frame number of that
  # tileset. For later tilesets, the frame numbering begins with the
  # next unused frame ID - so a tileset with room for 24 images
  # followed by a tileset with room for 6 images will have frame IDs
  # between 1 and 30 unless one of them sets first_frame_id.

  # Properties for animations: frames, after (opt). Frames is an array.
  # each element may be an integer, in which case it's a frame ID

  # The "after" property determines what happens after the given
  # frames have finished displaying. The default value of "stop" means
  # that the sprite stays on the last frame and doesn't change
  # again. A value of "loop" means the sprite will go back to the
  # first frame in the current named animation.  You can also set it
  # to the name of another animation - in the example above, you could
  # set "after" to "funny_walk", for instance. You can also set
  # "after" to an array of objects. If you do, these are all _choices_
  # for what happens when the named animation completes. The default
  # "chance" is 1.0, and all chances will be summed to determine what
  # the chance is out of - in order words, if you have four entries
  # with a chance of 1.0, each will have a 1/4 chance of being chosen
  # next. If you change one of them to have a chance of 2.0, then it
  # will have a 2/5ths chance and each other animation will have a 1/5
  # chance of being picked.

  # The "tileset" property of an animation gives the default tileset
  # for any frame that doesn't specify. The default value is the first
  # tileset.

  # The "frames" property of an animation is an array of frame
  # specifications. A frame can be a number, which is a frame number
  # as defined by the tilesets. A frame can also be a structure with a
  # duration and frame_id. Or it can be a structure with a duration,
  # an x and y coordinate for the upper left corner, a width and
  # height, and a tileset name.

  constructor: (data_hash) ->
    super(data_hash)

    images = (tileset.url for tileset in @displayable_data.params.tilesets)
    @tilesets = @displayable_data.params.tilesets

    @pixi_display.loader.addResourceBatch(images, () => @imagesLoaded())
    # @todo: how to make sure we can put this at a specific spot in the draw order, even if the load is slow

  imagesLoaded: () ->
    ts_base_textures = {}
    for tileset in @tilesets
      tileset.texture = @pixi_display.loader.getTexture(tileset.url)
      ts_base_textures[tileset.name] = tileset.texture.baseTexture

    # First, figure out the tile IDs
    tile_frame_definitions = Pixiurge.TileUtils.calculateFrames(@tilesets)

    @animations = {}
    # Next, we need to convert each animation to AnimatedSprite's format - an array of structures, each with "texture" and "time" fields.
    for animation_name, animation_struct of @displayable_data.params.animations
      anim_frames = []
      for frame in animation_struct.frames
        if typeof frame == "number"
          [x, y, tile_width, tile_height, tileset_name, reg_x, reg_y] = tile_frame_definitions[frame]
          rect = new PIXI.Rectangle(x, y, tile_width, tile_height)
          tex = new PIXI.Texture ts_base_textures[tileset_name], rect
          anim_frames.push time: 100, texture: tex
        else if typeof frame == "object" && frame.frame_id?
          [x, y, tile_width, tile_height, tileset_name, reg_x, reg_y] = tile_frame_definitions[frame.frame_id]
          rect = new PIXI.Rectangle(x, y, tile_width, tile_height)
          tex = new PIXI.Texture ts_base_textures[tileset_name], rect
          duration = if frame.duration? then frame.duration else 100
          anim_frames.push time: duration, texture: tex
        else if typeof frame == "object"
          tileset_name = if frame.tileset? then frame.tileset else @tilesets[0].name
          rect = new PIXI.Rectangle(frame.x, frame.y, frame.width, frame.height)
          tex = new PIXI.Texture ts_base_textures[tileset_name], rect
          duration = if frame.duration? then frame.duration else 100
          anim_frames.push time: duration, texture: tex
        else
          console.log "Unrecognized animation frame format in TileAnimatedSprite!", frame

      # The "after" fields will be handled later in @addDisplaySignalHandlers
      after = if animation_struct.after? then animation_struct.after else "stop"
      @animations[animation_name] = { frames: anim_frames, after: after }

    # Create the AnimatedSprite with the textures for the first animation
    @current_animation = @displayable_data.params.animation
    unless @current_animation?
      console.log "No current animation set for TileAnimatedSprite!"
    @sprite = new PIXI.extras.AnimatedSprite(@animations[@current_animation].frames)
    this_pixiurge_sprite = this
    @sprite.onComplete = () => this_pixiurge_sprite.animationComplete()

    disp_data = @displayable_data.displayable
    if disp_data.x? && disp_data.x && disp_data.y? && disp_data.y
      @sprite.x = disp_data.x * disp_data.location_block_width
      @sprite.y = disp_data.y * disp_data.location_block_height

    @addDisplaySignalHandlers()

    @parent_container.addChild @sprite
    @startAnimation @current_animation

  addDisplaySignalHandlers: () ->
    for animation_name, animation of @animations
      @pixi_display.onDisplayEvent "animationEnd", @displayable_name, (animEnd, dispName, eventData) =>
        anim = @animations[eventData.animation]
        if anim? && anim && anim.after? && anim.after
          @executeFrontEndEventCode(anim.after)

  # This needs to be generalized, get some new operations and move into the parent class
  executeFrontEndEventCode: (code) ->
    if code == "stop"
      return
    # We shouldn't normally get an animationEnd for a looped animation
    if code == "loop"
      return @startAnimation(@current_animation)
    if typeof(code) == "string"
      return @startAnimation(code)
    if typeof(code) == "object"
      chances = 0.0
      for item in code
        chances += (item.chance || 1.0)
      r = Math.random() * chances
      for item in code
        r -= (item.chance || 1.0)
        if r <= 0.0
          return @startAnimation(item.name)

      # Fallthrough - some kind of numerical error or other edge case?
      console.log "Unexpected remainder: #{r}", r
      return @startAnimation(code[0].name)
    console.log "Unrecognized code for front-end event:", code

  startAnimation: (name) ->
    @current_animation = name
    @sprite.stop()
    @sprite.textures = @animations[@current_animation].frames
    if @animations[@current_animation].after == "loop"
      @sprite.loop = true
    else
      @sprite.loop = false
    @sprite.gotoAndPlay(0)

  animationComplete: () ->
    @sendDisplayEvent("animationEnd", { animation: @current_animation })
