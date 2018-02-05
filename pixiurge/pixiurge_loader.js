/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS205: Consider reworking code to avoid use of IIFEs
 */
window.Pixiurge.Loader = class Loader {
    constructor(loaderClass) {
        if (loaderClass == null) { loaderClass = PIXI.loaders.Loader; }
        this.loaderClass = loaderClass;
        this.resourcesLoading = {};
        this.resourcesLoaded = {};
        this.batchId = 0;
    }

    // Why does this exist instead of being inlined? For starters, we're
    // going to need complicated logic to check the PIXI.js caches for
    // loaded Textures and BaseTextures at some point.
    getLoadStatus(url) {
        if (this.resourcesLoaded[url] != null) {
            return "loaded";
        } else if (this.resourcesLoading[url] != null) {
            return "loading";
        } else {
            return "unloaded";
        }
    }

    newBatchId() {
        this.batchId += 1;
        return this.batchId;
    }

    addResourceBatch(resources, handler) {
        const toLoad = [];
        const dependsOn = [];
        for (var url of Array.from(resources)) {
            const status = this.getLoadStatus(url);
            if (status === "unloaded") {
                toLoad.push(url);
            } else if (status === "loading") {
                const idx = dependsOn.indexOf(this.resourcesLoading[url].id);
                if (idx === -1) {
                    dependsOn.push(this.resourcesLoading[url].id);
                }
            }
        }
        if ((toLoad.length === 0) && (dependsOn.length === 0)) {
            return handler();
        }

        // Okay, so there's something to load and/or batches depended on
        const id = this.newBatchId();
        const loadingObj = { id, loading: toLoad, depends: dependsOn, required: [], loader: new this.loaderClass, handler, pixiHandler: (loader, resources) => this.batchLoaded(id) };
        for (let dep of Array.from(dependsOn)) {
            const req = this.resourcesLoading[dep].required;
            if (req[req.length - 1] !== id) {
                req.push(id);
            }
        }
        for (url of Array.from(toLoad)) { this.resourcesLoading[url] = loadingObj; }
        this.resourcesLoading[id] = loadingObj;

        return loadingObj.loader.add(toLoad).load(loadingObj.pixiHandler);
    }

    batchLoaded(id) {
        let idx;
        if (this.resourcesLoaded[id]) {
            return;
        }
        const loadingObj = this.resourcesLoading[id];

        // Are all of this batch's dependencies satisfied? If not, don't delete it or call the handler yet.
        if (loadingObj.depends.length !== 0) {
            return;
        }

        const dependentBatches = [];

        // Remove this as a dependency from anything waiting on it
        const removed = [];
        for (var depId of Array.from(loadingObj.required)) {
            const depList = this.resourcesLoading[depId].depends;
            idx = depList.indexOf(id);
            if (idx < 0) {
                console.log("LOADER ERROR: this should never fail to find the index!");
            } else {
                depList.splice(idx, 1);
                removed.push(depId);
            }
            if (depList.length === 0) {
                // This was the last dependency of the dependent batch
                dependentBatches.push(depId);
            }
        }
        for (depId of Array.from(removed)) {
            // For each dependency we marked done, mark it as no longer required
            idx = loadingObj.required.indexOf(depId);
            loadingObj.required.splice(idx, 1);
        }

        // Okay, we're good. Delete this from "loading", add it to "loaded", call the handler.
        for (var url of Array.from(loadingObj.loading)) {
            delete this.resourcesLoading[url];
        }
        delete this.resourcesLoading[id];
        const loadedObj = { batch: loadingObj.loading, loader: loadingObj.loader };
        for (url of Array.from(loadingObj.loading)) {
            this.resourcesLoaded[url] = loadedObj;
        }
        this.resourcesLoaded[id] = true;
        loadingObj.handler();

        // Now notify anybody else where we were their last dependency
        for (depId of Array.from(dependentBatches)) {
            this.batchLoaded(depId);
        }
    }

    getTexture(url) {
        const rsc = this.resourcesLoaded[url];
        if (rsc) {
            return this.resourcesLoaded[url].loader.resources[url].texture;
        } else {
            return console.log("Could not locate resource for texture URL!", url);
        }
    }

    getJSON(url) {
        const rsc = this.resourcesLoaded[url];
        if (rsc) {
            return this.resourcesLoaded[url].loader.resources[url].data;
        } else {
            return console.log("Could not locate resource for JSON URL!", url);
        }
    }
};
