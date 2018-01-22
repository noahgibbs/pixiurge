class Pixiurge.ParticleSource extends Pixiurge.Displayable
  constructor: (pixi_display, item_name, item_data) ->
    super(pixi_display, item_name, item_data)

    @texture_name = "/sprites/explosion00.png"
    PIXI.loader.add(@texture_name).load(() => @finished_loading())

  finished_loading: () ->
    @texture = PIXI.loader.resources[@texture_name]
    @emitter = new PIXI.particles.Emitter(pixi_display.stage, @texture, config)
