/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Pixiurge.TmxMap = class TmxMap extends Pixiurge.Displayable {
  constructor(dataHash) {
    super(dataHash);

    this.url = this.displayableData.url;
    this.pixiDisplay.loader.addResourceBatch([this.url], () => this.jsonLoaded());

    // Reserve our spot in the display order, even if the loader is slow
    this.world = new PIXI.Container();
    this.parentContainer.addChild(this.world);
  }

  // This is actually the "destroy" method for this Displayable
  hide() {}

  jsonLoaded() {
    const tmxCacheEntry = this.pixiDisplay.loader.getJSON(this.url);
    const tilesetImages = (Array.from(tmxCacheEntry.map.tilesets).map((tileset) => tileset.image));

    this.pixiDisplay.loader.addResourceBatch(tilesetImages, () => this.makeTiledWorld(tmxCacheEntry));
  }

  // Parts of this are adapted from kittykatattack's tileUtilities
  makeTiledWorld(tmxCacheEntry) {
    const layers = tmxCacheEntry.tile_layers.sort((l1, l2) => l1.z - l2.z);
    const tiledJSON = tmxCacheEntry.map;
    const tilesetSpec = [];
    const baseTextureByTileset = {};
    for (let tileset of Array.from(tiledJSON.tilesets)) {
      const tsSpecItem = {
        name: tileset.name,
        first_frame_id: tileset.firstgid,
        tile_width: tileset.tilewidth,
        tile_height: tileset.tileheight,
        spacing: tileset.spacing,
        margin: tileset.margin,
        texture: this.pixiDisplay.loader.getTexture(tileset.image),
      };
      baseTextureByTileset[tileset.name] = tsSpecItem.texture.baseTexture;
      tilesetSpec.push(tsSpecItem);
    }

    // Calculating gids is a "fun" process - if you use oversize
    // sprites, for instance, different layers may have different tile
    // widths and tile heights.
    const tileFrameDefinitions = Pixiurge.TileUtils.calculateFrames(tilesetSpec);
    const textureByGID = {};

    this.world.tileWidth = tiledJSON.tilewidth;
    this.world.tileHeight = tiledJSON.tileheight;

    this.world.worldWidth = tiledJSON.width * tiledJSON.tilewidth;
    this.world.worldHeight = tiledJSON.height * tiledJSON.tileheight;

    // @todo Change interface?
    this.world.widthInTiles = tiledJSON.width;
    this.world.heightInTiles = tiledJSON.height;

    for (var tiledLayer of Array.from(layers)) {
      if (tiledLayer.type === "tilelayer") {

        var layer = {
          name: tiledLayer.name,
          data: tiledLayer.data,
          container: new PIXI.Container(),
          properties: tiledLayer.properties,
          alpha: tiledLayer.opacity,
        };

        // Copy any other properties or keys into layer?

        this.world.addChild(layer.container);

        // @todo Should we break up large layers into multiple containers to facilitate quick rendering of a small chunk in a small viewport?

        for (let index = 0; index < tiledLayer.data.length; index++) {
          const gid = tiledLayer.data[index];
          if (gid !== 0) {  // A 0 GID means no tile is there
            var spriteTexture;
            const mapColumn = index % this.world.widthInTiles;
            const mapRow = Math.floor(index / this.world.widthInTiles);

            const mapX = mapColumn * this.world.tileWidth;
            const mapY = mapRow * this.world.tileHeight;

            // regX and regY are for variable pivots - important for oversize terrain tiles in Fringe layers and similar
            const [ tileX, tileY, tileWidth, tileHeight, imageName, regX, regY ] = Array.from(tileFrameDefinitions[gid]);

            // Look up or allocate a texture for this tile
            // @todo Use the PIXI global texture cache for this
            if (textureByGID[gid] != null) {
              spriteTexture = textureByGID[gid];
            } else {
              const rect = new PIXI.Rectangle(tileX, tileY, tileWidth, tileHeight);
              spriteTexture = new PIXI.Texture(baseTextureByTileset[imageName], rect);
              textureByGID[gid] = spriteTexture;
            }

            // @todo AnimatedSprites for animated terrain
            const sprite = new PIXI.Sprite(spriteTexture);
            sprite.x = mapX;
            sprite.y = mapY;
            sprite.pivot = new PIXI.Point(regX, regY);
            layer.container.addChild(sprite);
          }
        }
      }
    }
  }
};
