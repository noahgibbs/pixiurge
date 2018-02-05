Pixiurge.ParticleSource = class ParticleSource extends Pixiurge.Displayable {
    constructor(dataHash) {
        super(dataHash);

        this.textureName = "/sprites/explosion00.png";
        PIXI.loader.add(this.textureName).load(() => this.finished_loading());
    }

    finished_loading() {
        this.texture = PIXI.loader.resources[this.textureName];
        this.emitter = new PIXI.particles.Emitter(this.parent_container, this.texture, config);
    }
};
