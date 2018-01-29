class Pixiurge.ParticleSource extends Pixiurge.Displayable
  constructor: (data_hash) ->
    super(data_hash)

    @texture_name = "/sprites/explosion00.png"
    PIXI.loader.add(@texture_name).load(() => @finished_loading())

  finished_loading: () ->
    @texture = PIXI.loader.resources[@texture_name]
    @emitter = new PIXI.particles.Emitter(@parent_container, @texture, config)
