Pixiurge.JsonDisplay = class JsonDisplay extends Pixiurge.Displayable {
    constructor(dataHash) {
        super(dataHash);

        // This uses no assets, and so it doesn't need a loader.
        this.htmlElement = dataHash["element"];

        // TODO: add state subscription(s)
    }
};
