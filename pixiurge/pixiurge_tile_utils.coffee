# This is just a namespace for tile-related functions
Pixiurge.TileUtils = {

  # calculate_frames takes tileset specifications and figures out what
  # frame IDs correspond to what coordinates in what textures.  Here
  # is a "tilesets" array, such as the third argument:
  #
  #   [
  #     {
  #       name: "name1",
  #       texture: firstTextureObject,
  #       tile_width: 32,
  #       tile_height: 32,
  #     },
  #     {
  #       name: "name2",
  #       texture: secondTextureObject,
  #       tile_width: 32,
  #       tile_height: 32,
  #       first_frame_id: 7,  # Optional field, default 1
  #       spacing: 3, # Optional field, default 0
  #       margin: 2,  # Optional field, default 0
  #       reg_x: 0,  # Optional field for pivot/registration x coord, default 0
  #       reg_y: 0,  # Optional field for pivot/registration y coord, default 0
  #     }
  #   ],
  #
  # calculate_frames will return an array of frame specifications so
  # that frame_specs[idx] will return the specific tile with the frame
  # ID "idx". The frame specs are of this form:
  #
  #   [ upper_left_x, upper_left_y, width, height, image_name, reg_x, reg_y ]
  #
  # The final three numbers are optional.
  # The Demiurge SpriteSheet objects are hashes, with fields including:
  # "firstgid", "image", "imagewidth", "imageheight", "tile_width", "tile_height", "oversize", "spacing", "margin"
  # Currently we use ManaSource-style spritesheets for terrain with a primary "natural" tile size
  # and occasional "oversize" sheets that are a multiple of this size. Oversize sprites have a tile location
  # at the "natural" size and just extend upward and rightward from there. They're only used in the "Fringe"
  # layer(s) with interesting Z coordinates - oversize objects in the layers that are always above or below
  # the agent sprites don't need to be treated specially since they don't interleave in unusual ways. They're
  # always either all-below or all-above the player and can just be handled with a lot of tiles of the natural
  # size.
  calculateFrames: (tilesets) ->
    frameDefinitions = {}

    deadFrame = [ 0, 0, 0, 0, 0, 0, 0 ] # Use the first natural-size tile of the first image for dead frames.
    frameDefinitions = [ deadFrame ]  # GIDs start at 1, so array offset 0 is always a dead frame.
    frameCount = 1

    for tileset in tilesets
      spacing = if tileset.spacing? then tileset.spacing else 0
      margin = if tileset.margin? then tileset.margin else 0
      if tileset.first_frame_id?
        firstFid = tileset.first_frame_id
      else
        firstFid = frameCount

      # Each new tileset specifies its starting GID. This may require pushing dead frames to pad
      # to the correct frame-number/GID.
      deadFrames = firstFid - frameCount
      if deadFrames < 0
        console.log "ERROR: GIDs are specified badly in tilesets! You are likely to see wrong tiles!"
      else if deadFrames > 0
        frameDefinitions.push(deadFrame) for num in [1..deadFrames]
        frameCount += deadFrames

      totalWidth = tileset.texture.baseTexture.realWidth
      totalHeight = tileset.texture.baseTexture.realHeight

      # Oversize tilesets may have their own tile_width and tile_height; not all tiles need to be the same size
      tileWidth = tileset.tile_width
      tileHeight = tileset.tile_height
      regX = if tileset.reg_x? then tileset.reg_x else 0
      regY = if tileset.reg_y? then tileset.reg_y else 0

      y = margin
      while y <= totalHeight - margin - tileHeight
        x = margin
        while x <= totalWidth - margin - tileWidth
          frameCount += 1
          frameDefinitions.push [ x, y, tileWidth, tileHeight, tileset.name, regX, regY ]
          x += tileWidth + spacing
        y += tileHeight + spacing

    frameDefinitions
}
