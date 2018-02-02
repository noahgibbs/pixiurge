class Pixiurge.ParticleSource extends Pixiurge.Displayable
  constructor: (dataHash) ->
    super(dataHash)

    @textureName = "/sprites/explosion00.png"
    PIXI.loader.add(@textureName).load(() => @finished_loading())

  finished_loading: () ->
    @texture = PIXI.loader.resources[@textureName]
    @emitter = new PIXI.particles.Emitter(@parent_container, @texture, config)
