// Pixi display for Pixiurge. Mostly this is a message handler to
// dispatch to more specific Pixi drawing classes.

const messageMap = {
    "display_init": "initMessage",
    "display_show": "showDisplayable",
    "display_destroy": "destroyDisplayable",
    "display_destroy_all": "destroyAllDisplayables",
    "display_move": "moveDisplayable",
    "display_pan": "panToPixel",
    "": ""
};

Pixiurge.DisplayEvent = class DisplayEvent {
    constructor(eventName, objectName, eventData) {
        this.name = eventName;
        this.objectName = objectName;
        this.data = eventData;
        this.prevented = false;
    }
    // Let's just steal the interface from DOM events
    preventDefault() {
        this.prevented = true;
    }
};

Pixiurge.Display = class Display {
    constructor(pixiurge, options) {
        this.pixiurge = pixiurge;
        if (options == null) { options = {}; }
        this.pixiurge.display = this;
        this.displayables = {};
        this.transientEffectCounter = 0;
        this.displayEventHandlers = {};

        this.containerSpec = options["container"] || "body";
        this.pixiOptions = options["pixiOptions"] || {};
        this.itemKlasses = {
            particle_source: Pixiurge.ParticleSource,
            tile_animated_sprite: Pixiurge.TileAnimatedSprite,
            tmx: Pixiurge.TmxMap,
            container: Pixiurge.DisplayContainer,
            text_effect: Pixiurge.TextEffect
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
        this[handler](...(argArray || []));
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
        if("any" === itemName || "all" === itemName) {
            console.log(`Illegal item name '${itemName}'!`);
        }
        if(this.displayables[itemName]) {
            console.log(`Item name '${itemName}' already exists!`);
            return;
        }
        if("" === itemName) {
            // Empty item names are normally for transient effects
            // which won't be controlled.  They generally fade on
            // their own and/or are removed via
            // DestroyAllDisplayables.
            itemName = `@transientEffect${this.transientEffectCounter}`
            this.transientEffectCounter++;
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
        return new klass({pixiDisplay: this, parentContainer: parentContainer, displayableName: itemName, displayableData: itemData});
    }

    // This destroys this Displayable - it won't be referenced by name
    // again, ever (unless you recreate it.)
    destroyDisplayable(itemName) {
        if (this.displayables[itemName]) {
            this.displayables[itemName].destroy();
            delete this.displayables[itemName];
        }
    }

    // This destroys all Displayables and invalidates any hints or preloads.
    destroyAllDisplayables() {
        for (let itemName in this.displayables) {
            const displayable = this.displayables[itemName];
            displayable.destroy();
        }
        this.displayables = {};
    }

    // Move a Displayable to its new location. data.options can
    // describe how to move it to that location. The sequence of
    // occurrences is:
    //
    // * send a DisplayEvent with the motion
    // * if the DisplayEvent is unhandled, call the Displayable with moveTo
    //
    // The DisplayEvent allows the application to override a motion on
    // one or more Displayables if it wants to alter how a motion
    // occurs (walking, hopping, etc) on various sorts of
    // Displayables.
    //
    // This "position" is a Demiurge position, and needs to be
    // multiplied by block size or otherwise mapped to a pixel
    // location.
    moveDisplayable(itemName, data) {
        const displayable = this.displayables[itemName];
        const newPosition = data.position;
        const [location, coords] = newPosition.split("#", 2);
        if(coords == null)
            return;
        const [x, y] = coords.split(",");
        displayable.moveTo(x, y, data.options);
    }

    // Register a handler for a DisplayEvent on the given
    // objectName. The handler will receive a single DisplayEvent
    // object with the accessors .name, .objectName, .data, .prevented
    // and the method .preventDefault().
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

    // Send a DisplayEvent. A DisplayEvent will notify down the list
    // of handlers until something marks it "handled", and then it
    // will stop.
    sendDisplayEvent(event, objectName, data, defaultCallback = null) {
        if (this.displayEventHandlers[event] == null) {
            return;
        }
        let eventObject = new Pixiurge.DisplayEvent(event, objectName, data);
        for (handler of (this.displayEventHandlers[objectName] || [])) {
            handler(eventObject);
            if(eventObject.prevented)
                break;
        }
        if(!eventObject.prevented) {
            for (var handler of this.displayEventHandlers[event].any) {
                handler(eventObject);
                if(eventObject.prevented)
                    break;
            }
        }
        if(!eventObject.prevented && defaultCallback) {
            defaultCallback(event);
        }
    }
};
