Pixiurge.DisplayContainer = class DisplayContainer extends Pixiurge.Displayable {
    constructor(dataHash) {
        super(dataHash);

        const contentsMessages = this.displayableData.contents;
        this.pixiContainer = new PIXI.Container();
        this.parentContainer.addChild(this.pixiContainer);

        const dispData = this.displayableData.displayable;
        if ((dispData.x != null) && dispData.x && (dispData.y != null) && dispData.y) {
            this.pixiContainer.x = dispData.x * dispData.location_block_width;
            this.pixiContainer.y = dispData.y * dispData.location_block_height;
        }

        // This won't instantly load everything. Lots of Displayable types put stuff into a loader and load over time.
        this.contents = contentsMessages.map((msgs) => this.pixiDisplay.createDisplayableFromMessages(this.pixiContainer, msgs[0].name, msgs[0]));
    }

    moveTo(x, y, options) {
        const dispData = this.displayableData.displayable;
        // @todo: Tweening
        this.pixiContainer.x = x * dispData.location_block_width;
        this.pixiContainer.y = y * dispData.location_block_height;
    }

    destroy() {
        this.contents.map((displayable) => displayable.destroy());
        this.parentContainer.removeChild(this.pixiContainer);
        this.pixiContainer.destroy({ children: true });
    }
};
