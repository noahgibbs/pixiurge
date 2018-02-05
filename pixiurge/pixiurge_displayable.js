// Here's the parent class for Displayables
Pixiurge.Displayable = class Displayable {
    constructor(dataHash) {
        this.parentContainer = dataHash.parentContainer;
        this.displayableName = dataHash.displayableName;
        this.displayableData = dataHash.displayableData;
        this.pixiDisplay = dataHash.pixiDisplay;
    }

    show() {}

    destroy() {
        throw("Implement me!");
    }

    sendDisplayEvent(eventName, eventData) {
        this.pixiDisplay.sendDisplayEvent(eventName, this.displayableName, eventData);
    }
};
