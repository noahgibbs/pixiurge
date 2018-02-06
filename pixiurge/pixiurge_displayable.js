// Here's the parent class for Displayables
Pixiurge.Displayable = class Displayable {
    constructor(dataHash) {
        this.parentContainer = dataHash.parentContainer;
        this.displayableName = dataHash.displayableName;
        this.displayableData = dataHash.displayableData;
        this.pixiDisplay = dataHash.pixiDisplay;
    }

    destroy() {
        throw(`Implement destroy! ${this.displayableName}`);
    }

    moveTo(x, y, options) {
        throw(`Implement moveTo! ${this.displayableName}`);
    }

    sendDisplayEvent(eventName, eventData) {
        this.pixiDisplay.sendDisplayEvent(eventName, this.displayableName, eventData);
    }
};
