if(window.Mock === undefined) {
  window.Mock = {
  };
};

window.Mock.MockLoader = class {
    constructor() {
        this._batches = [];
        this._resources = {};
    }

    add(url_or_urls) {
        var urls = this.urlsToList(url_or_urls);
        this._batches.push({ id: urls.join(","), urls: urls });
        return this;
    }

    load(callback) {
        this._batches[this._batches.length - 1].callback = callback
        return this;
    }

    urlsToList(url_or_urls) {
        if(typeof(url_or_urls) == "string")
            return [ url_or_urls ];
        return url_or_urls;
    }

    completeFakeLoad(url_or_urls) {
        var urls = this.urlsToList(url_or_urls);
        var urlId = urls.join(",");
        var batchIndex = -1;

        // Locate the "loading" batch object for these resources
        for(var i = 0; i < this._batches.length; i++) {
            if(this._batches[i].id === urlId) {
                batchIndex = i;
                break;
            }
        }
        if(batchIndex > -1) {
            var batch = this._batches[batchIndex];
            var loaderResources = {};

            this._batches.splice(batchIndex, 1); // Remove that batch from the ones loading
            // Add the resources from that batch to the loaded-resources object
            for(var i = 0; i < batch.urls.length; i++) {
                var url = batch.urls[i];
                loaderResources[url] = { texture: { fake: "texture" }, data: { fake: "JSON" } };
                this._resources[url] = { url: url, batch: urlId, resources: loaderResources };
            }
            batch.callback();
        } else {
            console.log("Couldn't find batch index for URLs:", urls.join(","));
            return;
        }
    }
};
