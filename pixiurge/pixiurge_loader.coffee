class window.Pixiurge.Loader
  constructor: (@loader_class = PIXI.loaders.Loader) ->
    @resources_loading = {}
    @resources_loaded = {}
    @batch_id = 0

  # Why does this exist instead of being inlined? For starters, we're
  # going to need complicated logic to check the PIXI.js caches for
  # loaded Textures and BaseTextures at some point.
  getLoadStatus: (url) ->
    if @resources_loaded[url]?
      "loaded"
    else if @resources_loading[url]?
      "loading"
    else
      "unloaded"

  newBatchId: () ->
    @batch_id += 1
    return @batch_id

  addResourceBatch: (resources, handler) ->
    to_load = []
    depends_on = []
    for url in resources
      status = @getLoadStatus(url)
      if status == "unloaded"
        to_load.push(url)
      else if status == "loading"
        idx = depends_on.indexOf(@resources_loading[url].id)
        if idx == -1
          depends_on.push @resources_loading[url].id
    if to_load.length == 0 && depends_on.length == 0
      return handler()

    # Okay, so there's something to load and/or batches depended on
    id = @newBatchId()
    loading_obj = { id: id, loading: to_load, depends: depends_on, required: [], loader: new @loader_class, handler: handler, pixi_handler: (loader, resources) => @batchLoaded(id) }
    for dep in depends_on
      req = @resources_loading[dep].required
      unless req[req.length - 1] == id
        req.push id
    @resources_loading[url] = loading_obj for url in to_load
    @resources_loading[id] = loading_obj

    loading_obj.loader.add(to_load).load(loading_obj.pixi_handler)

  batchLoaded: (id) ->
    if @resources_loaded[id]
      return
    loading_obj = @resources_loading[id]

    # Are all of this batch's dependencies satisfied? If not, don't delete it or call the handler yet.
    unless loading_obj.depends.length == 0
      return

    dependent_batches = []

    # Remove this as a dependency from anything waiting on it
    removed = []
    for dep_id in loading_obj.required
      dep_list = @resources_loading[dep_id].depends
      idx = dep_list.indexOf(id)
      if idx < 0
        console.log "LOADER ERROR: this should never fail to find the index!"
      else
        dep_list.splice(idx, 1)
        removed.push(dep_id)
      if dep_list.length == 0
        # This was the last dependency of the dependent batch
        dependent_batches.push(dep_id)
    for dep_id in removed
      # For each dependency we marked done, mark it as no longer required
      idx = loading_obj.required.indexOf(dep_id)
      loading_obj.required.splice(idx, 1)

    # Okay, we're good. Delete this from "loading", add it to "loaded", call the handler.
    for url in loading_obj.loading
      delete @resources_loading[url]
    delete @resources_loading[id]
    loaded_obj = { batch: loading_obj.loading, loader: loading_obj.loader }
    for url in loading_obj.loading
      @resources_loaded[url] = loaded_obj
    @resources_loaded[id] = true
    loading_obj.handler()

    # Now notify anybody else where we were their last dependency
    for dep_id in dependent_batches
      @batchLoaded(dep_id)

  getTexture: (url) ->
    rsc = @resources_loaded[url]
    if rsc
      return @resources_loaded[url].loader.resources[url].texture
    else
      console.log "Could not locate resource for texture URL!", url

  getJSON: (url) ->
    rsc = @resources_loaded[url]
    if rsc
      return @resources_loaded[url].loader.resources[url].data
    else
      console.log "Could not locate resource for JSON URL!", url
