class window.Pixiurge.Loader
  constructor: (@loaderClass = PIXI.loaders.Loader) ->
    @resourcesLoading = {}
    @resourcesLoaded = {}
    @batchId = 0

  # Why does this exist instead of being inlined? For starters, we're
  # going to need complicated logic to check the PIXI.js caches for
  # loaded Textures and BaseTextures at some point.
  getLoadStatus: (url) ->
    if @resourcesLoaded[url]?
      "loaded"
    else if @resourcesLoading[url]?
      "loading"
    else
      "unloaded"

  newBatchId: () ->
    @batchId += 1
    return @batchId

  addResourceBatch: (resources, handler) ->
    toLoad = []
    dependsOn = []
    for url in resources
      status = @getLoadStatus(url)
      if status == "unloaded"
        toLoad.push(url)
      else if status == "loading"
        idx = dependsOn.indexOf(@resourcesLoading[url].id)
        if idx == -1
          dependsOn.push @resourcesLoading[url].id
    if toLoad.length == 0 && dependsOn.length == 0
      return handler()

    # Okay, so there's something to load and/or batches depended on
    id = @newBatchId()
    loadingObj = { id: id, loading: toLoad, depends: dependsOn, required: [], loader: new @loaderClass, handler: handler, pixiHandler: (loader, resources) => @batchLoaded(id) }
    for dep in dependsOn
      req = @resourcesLoading[dep].required
      unless req[req.length - 1] == id
        req.push id
    @resourcesLoading[url] = loadingObj for url in toLoad
    @resourcesLoading[id] = loadingObj

    loadingObj.loader.add(toLoad).load(loadingObj.pixiHandler)

  batchLoaded: (id) ->
    if @resourcesLoaded[id]
      return
    loadingObj = @resourcesLoading[id]

    # Are all of this batch's dependencies satisfied? If not, don't delete it or call the handler yet.
    unless loadingObj.depends.length == 0
      return

    dependentBatches = []

    # Remove this as a dependency from anything waiting on it
    removed = []
    for depId in loadingObj.required
      depList = @resourcesLoading[depId].depends
      idx = depList.indexOf(id)
      if idx < 0
        console.log "LOADER ERROR: this should never fail to find the index!"
      else
        depList.splice(idx, 1)
        removed.push(depId)
      if depList.length == 0
        # This was the last dependency of the dependent batch
        dependentBatches.push(depId)
    for depId in removed
      # For each dependency we marked done, mark it as no longer required
      idx = loadingObj.required.indexOf(depId)
      loadingObj.required.splice(idx, 1)

    # Okay, we're good. Delete this from "loading", add it to "loaded", call the handler.
    for url in loadingObj.loading
      delete @resourcesLoading[url]
    delete @resourcesLoading[id]
    loadedObj = { batch: loadingObj.loading, loader: loadingObj.loader }
    for url in loadingObj.loading
      @resourcesLoaded[url] = loadedObj
    @resourcesLoaded[id] = true
    loadingObj.handler()

    # Now notify anybody else where we were their last dependency
    for depId in dependentBatches
      @batchLoaded(depId)

  getTexture: (url) ->
    rsc = @resourcesLoaded[url]
    if rsc
      return @resourcesLoaded[url].loader.resources[url].texture
    else
      console.log "Could not locate resource for texture URL!", url

  getJSON: (url) ->
    rsc = @resourcesLoaded[url]
    if rsc
      return @resourcesLoaded[url].loader.resources[url].data
    else
      console.log "Could not locate resource for JSON URL!", url
