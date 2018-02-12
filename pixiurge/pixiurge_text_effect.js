// TextEffect is transient Text, assumed to exist only briefly and
// then fade.  For style parameters, see
// "http://pixijs.download/dev/docs/PIXI.TextStyle.html".
//
// Data fields:
//
// text - the words to show
// style - these are the PIXI.TextStyle parameters
// duration - how long the text should remain before expiring, default 5 seconds
// finalProperties - what property values to Tween to; defaults to rising upward and fading
Pixiurge.TextEffect = class TextEffect extends Pixiurge.Displayable {
    constructor(dataHash) {
        super(dataHash);

        const dispData = this.displayableData;
        const style = new PIXI.TextStyle(dispData.style || {});
        this.textObj = new PIXI.Text(dispData.text); //, style);

        this.textObj.x = dispData.displayable.x * dispData.displayable.location_block_width;
        this.textObj.y = dispData.displayable.y * dispData.displayable.location_block_height;

        this.duration = dataHash.duration || 5000;

        this.parentContainer.addChild(this.textObj);

        let finalProps = this.displayableData.finalProperties || { y: "-20", alpha: 0.1 };

        // Can also call tween.easing() to adjust the easing curve. Do that?
        //this.tween = new TWEEN.Tween(this.textObj)
        //    .to(finalProps, this.duration)
        //    .onComplete((self) => { this.destroy(); })
        //    .onStop((self) => { this.destroy(); })
        //    .start();
    }

    destroy() {
        this.tween.stop();
        this.parentContainer.removeChild(this.textObj);
        this.textObj.destroy({ children: true });  // Don't destroy texture or baseTexture by default
    }

};
