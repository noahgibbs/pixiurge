class Pixiurge.TmxMap extends Pixiurge.Displayable
  constructor: (pixi_display, item_name, item_data) ->
    super(pixi_display, item_name, item_data)

    @url = item_data.url
    @loader = new PIXI.loaders.Loader()
    @loader.add(@url).load(() => @jsonLoaded())

  # This is actually the "destroy" method for this Displayable
  hide: () ->

  jsonLoaded: () ->
    tiledJSON = @loader.resources[@url].data
    @loader.reset()
    tilesetImages = (tileset.image for tileset in tiledJSON.tilesets)

    @loader.add(tilesetImages).load(() => @makeTiledWorld(tiledJSON))

  # Parts of this are adapted from kittykatattack's tileUtilities
  makeTiledWorld: (tiledJSON) ->
    tileset_spec = []
    base_texture_by_tileset = {}
    for tileset in tiledJSON.tilesets
      ts_spec_item = {
        name: tileset.name,
        first_frame_id: tileset.firstgid,
        tile_width: tileset.tilewidth,
        tile_height: tileset.tileheight,
        spacing: tileset.spacing,
        margin: tileset.margin,
        texture: @loader.resources[tileset.image].texture,
      }
      base_texture_by_tileset[tileset.name] = ts_spec_item.texture.baseTexture
      tileset_spec.push ts_spec_item

    # Calculating gids is a "fun" process - if you use oversize
    # sprites, for instance, different layers may have different tile
    # widths and tile heights.
    tile_frame_definitions = Pixiurge.TileUtils.calculate_frames(tileset_spec)
    textureByGID = {}

    world = new PIXI.Container()

    world.tileWidth = tiledJSON.tilewidth
    world.tileHeight = tiledJSON.tileheight

    world.worldWidth = tiledJSON.width * tiledJSON.tilewidth
    world.worldHeight = tiledJSON.height * tiledJSON.tileheight

    # @todo Change interface?
    world.widthInTiles = tiledJSON.width;
    world.heightInTiles = tiledJSON.height;

    for tiledLayer in tiledJSON.layers
      if tiledLayer.type == "tilelayer" && tiledLayer.name != "Collision" && tiledLayer.name != "collision"

        layer = {
          name: tiledLayer.name,
          data: tiledLayer.data,
          container: new PIXI.Container(),
          properties: tiledLayer.properties,
          alpha: tiledLayer.opacity,
        }

        # Copy any other properties or keys into layer?

        world.addChild layer.container

        # @todo Should we break up large layers into multiple containers to facilitate quick rendering of a small chunk in a small viewport?

        for gid, index in tiledLayer.data
          if gid != 0  # A 0 GID means no tile is there
            mapColumn = index % world.widthInTiles
            mapRow = Math.floor(index / world.widthInTiles)

            mapX = mapColumn * world.tileWidth
            mapY = mapRow * world.tileHeight

            # regX and regY are for variable pivots - important for oversize terrain tiles in Fringe layers and similar
            [ tileX, tileY, tileWidth, tileHeight, imageName, regX, regY ] = tile_frame_definitions[gid]

            # Look up or allocate a texture for this tile
            # @todo Use the PIXI global texture cache for this
            if textureByGID[gid]?
              spriteTexture = textureByGID[gid]
            else
              rect = new PIXI.Rectangle(tileX, tileY, tileWidth, tileHeight)
              spriteTexture = new PIXI.Texture(base_texture_by_tileset[imageName], rect)
              textureByGID[gid] = spriteTexture

            # @todo AnimatedSprites for animated terrain
            sprite = new PIXI.Sprite(spriteTexture)
            sprite.x = mapX
            sprite.y = mapY
            sprite.pivot = new PIXI.Point(regX, regY)
            layer.container.addChild sprite

    @pixi_display.stage.addChild world
