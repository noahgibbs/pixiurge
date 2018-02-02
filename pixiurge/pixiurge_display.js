/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS205: Consider reworking code to avoid use of IIFEs
 */
// Pixi display for Pixiurge. Mostly this is a message handler to
// dispatch to more specific Pixi drawing classes.

const messageMap = {
  "display_init": "initMessage",
  "display_show": "showDisplayable",
  "display_destroy": "destroyDisplayable",
  "display_destroy_all": "destroyAllDisplayables",
  "display_pan": "panToPixel",
};

Pixiurge.Display = class Display {
  constructor(pixiurge, options) {
    this.pixiurge = pixiurge;
    if (options == null) { options = {}; }
    this.pixiurge.display = this;
    this.displayables = {};
    this.displayEventHandlers = {};

    this.containerSpec = options["container"] || "body";
    this.pixiOptions = options["pixiOptions"] || {};
    this.itemKlasses = {
      particle_source: Pixiurge.ParticleSource,
      tile_animated_sprite: Pixiurge.TileAnimatedSprite,
      tmx: Pixiurge.TmxMap,
      container: Pixiurge.DisplayContainer,
    };
    this.loader = new Pixiurge.Loader();
  }

  setup() {}

  pixiSetup() {
    this.exposure = { x: this.displayWidth / 2, y: this.displayHeight / 2, width: this.displayWidth, height: this.displayHeight };

    const pixiAppOptions = { width: this.displayWidth, height: this.displayHeight };
    for (let key in this.pixiOptions) { const value = this.pixiOptions[key]; pixiAppOptions[key] = value; }
    this.pixiApp = new PIXI.Application(pixiAppOptions);
    this.stage = this.pixiApp.stage;
    $(this.containerSpec).append(this.pixiApp.view);

    // Later figure out Z-ordering: http://pixijs.io/examples/#/layers/zorder.js
    this.layersContainer = new PIXI.Container;
    this.stage.addChild(this.layersContainer);
    this.fringeContainer = new PIXI.Container;
    this.fringeContainer.z = 0;
    this.layersContainer.addChild(this.fringeContainer);
  }

  message(msgName, argArray) {
    const handler = messageMap[msgName];
    if ((handler == null) || !this[handler]) {
      console.warn(`Couldn't handle message type ${msgName}!`);
      return;
    }
    this[handler](...Array.from(argArray || []));
  }

  initMessage(data) {
    console.log("Pixiurge Init Message", data);
    this.displayWidth = data.width;
    this.displayHeight = data.height;
    this.msPerTick = data.ms_per_tick;
    this.pixiSetup();
  }

  panToPixel(x, y) {
    this.exposure = { x, y, width: this.displayWidth, height: this.displayHeight };
    const leftX = this.exposure.x - (this.exposure.width - (this.displayWidth / 2));
    const upperY = this.exposure.y - (this.exposure.height - (this.displayHeight / 2));
    this.layersContainer.x = -leftX;
    this.layersContainer.y = -upperY;
  }

  showDisplayable(itemName, itemData) {
    if (this.displayables[itemName]) {
      console.log(`Item name '${itemName}' already exists!`);
      return;
    }
    const displayable = this.createDisplayableFromMessages(this.layersContainer, itemName, itemData);
    if ((displayable == null) || !displayable) {
      console.log(`Got back undefined or false displayable from creation: ${displayable}`, displayable);
      return;
    }
    this.displayables[itemName] = displayable;
  }

  createDisplayableFromMessages(parentContainer, itemName, itemData) {
    const itemType = itemData.type;
    const klass = this.itemKlasses[itemType];
    if (klass == null) {
      console.log(`Couldn't find a class for item type: ${itemType}!`);
      return undefined;
    }
    return new klass({pixiDisplay: this, parentContainer, displayableName: itemName, displayableData: itemData});
  }

  // This destroys this Displayable - it won't be referenced by name
  // again, ever (unless you recreate it.)
  destroyDisplayable(itemName) {
    if (this.displayables[itemName]) {
      this.displayables[itemName].destroy();
      this.displayables.delete(itemName);
    }
  }

  // This destroys all Displayables and invalidates any hints or preloads
  destroyAllDisplayables() {
    for (let itemName in this.displayables) {
      const displayable = this.displayables[itemName];
      displayable.destroy();
    }
    this.displayables = {};
  }

  onDisplayEvent(event, objectName, handler) {
    if (this.displayEventHandlers[event] == null) {
      this.displayEventHandlers[event] = { any: [] };
    }
    this.displayEventHandlers[event].any.push(handler);
    if (this.displayEventHandlers[event][objectName] == null) {
      this.displayEventHandlers[event][objectName] = [];
    }
    this.displayEventHandlers[event][objectName].push(handler);
  }

  sendDisplayEvent(event, objectName, data) {
    if (this.displayEventHandlers[event] == null) {
      return;
    }
    for (var handler of Array.from(this.displayEventHandlers[event].any)) {
      handler(event, objectName, data);
    }
    for (handler of Array.from((this.displayEventHandlers[objectName] || []))) {
      handler(event, objectName, data);
    }
  }
};
