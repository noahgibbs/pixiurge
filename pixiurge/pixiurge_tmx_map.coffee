class Pixiurge.TmxMap extends Pixiurge.Displayable
  constructor: (dataHash) ->
    super(dataHash)

    @url = @displayableData.url
    @pixiDisplay.loader.addResourceBatch([@url], () => @jsonLoaded())

    # Reserve our spot in the display order, even if the loader is slow
    @world = new PIXI.Container()
    @parentContainer.addChild @world

  # This is actually the "destroy" method for this Displayable
  hide: () ->

  jsonLoaded: () ->
    tmxCacheEntry = @pixiDisplay.loader.getJSON(@url)
    tilesetImages = (tileset.image for tileset in tmxCacheEntry.map.tilesets)

    @pixiDisplay.loader.addResourceBatch(tilesetImages, () => @makeTiledWorld(tmxCacheEntry))

  # Parts of this are adapted from kittykatattack's tileUtilities
  makeTiledWorld: (tmxCacheEntry) ->
    layers = tmxCacheEntry.tile_layers.sort (l1, l2) -> l1.z - l2.z
    tiledJSON = tmxCacheEntry.map
    tilesetSpec = []
    baseTextureByTileset = {}
    for tileset in tiledJSON.tilesets
      tsSpecItem = {
        name: tileset.name,
        first_frame_id: tileset.firstgid,
        tile_width: tileset.tilewidth,
        tile_height: tileset.tileheight,
        spacing: tileset.spacing,
        margin: tileset.margin,
        texture: @pixiDisplay.loader.getTexture(tileset.image),
      }
      baseTextureByTileset[tileset.name] = tsSpecItem.texture.baseTexture
      tilesetSpec.push tsSpecItem

    # Calculating gids is a "fun" process - if you use oversize
    # sprites, for instance, different layers may have different tile
    # widths and tile heights.
    tileFrameDefinitions = Pixiurge.TileUtils.calculateFrames(tilesetSpec)
    textureByGID = {}

    @world.tileWidth = tiledJSON.tilewidth
    @world.tileHeight = tiledJSON.tileheight

    @world.worldWidth = tiledJSON.width * tiledJSON.tilewidth
    @world.worldHeight = tiledJSON.height * tiledJSON.tileheight

    # @todo Change interface?
    @world.widthInTiles = tiledJSON.width;
    @world.heightInTiles = tiledJSON.height;

    for tiledLayer in layers
      if tiledLayer.type == "tilelayer"

        layer = {
          name: tiledLayer.name,
          data: tiledLayer.data,
          container: new PIXI.Container(),
          properties: tiledLayer.properties,
          alpha: tiledLayer.opacity,
        }

        # Copy any other properties or keys into layer?

        @world.addChild layer.container

        # @todo Should we break up large layers into multiple containers to facilitate quick rendering of a small chunk in a small viewport?

        for gid, index in tiledLayer.data
          if gid != 0  # A 0 GID means no tile is there
            mapColumn = index % @world.widthInTiles
            mapRow = Math.floor(index / @world.widthInTiles)

            mapX = mapColumn * @world.tileWidth
            mapY = mapRow * @world.tileHeight

            # regX and regY are for variable pivots - important for oversize terrain tiles in Fringe layers and similar
            [ tileX, tileY, tileWidth, tileHeight, imageName, regX, regY ] = tileFrameDefinitions[gid]

            # Look up or allocate a texture for this tile
            # @todo Use the PIXI global texture cache for this
            if textureByGID[gid]?
              spriteTexture = textureByGID[gid]
            else
              rect = new PIXI.Rectangle(tileX, tileY, tileWidth, tileHeight)
              spriteTexture = new PIXI.Texture(baseTextureByTileset[imageName], rect)
              textureByGID[gid] = spriteTexture

            # @todo AnimatedSprites for animated terrain
            sprite = new PIXI.Sprite(spriteTexture)
            sprite.x = mapX
            sprite.y = mapY
            sprite.pivot = new PIXI.Point(regX, regY)
            layer.container.addChild sprite
