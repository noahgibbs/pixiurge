const assert = require('assert');

describe('Pixiurge loader', function() {
    it('should call back successfully when configured with no failures, single batch', function(done) {
        assert.notEqual(undefined, window.Pixiurge);

        // Create a new Pixiurge loader with a mocked PIXI.loaders.Loader class behind it
        var loader = new window.Pixiurge.Loader(window.Mock.MockLoader);

        var urls = ["https://fake_url_1/fake.png", "https://fake_url_2/fake.json"];
        loader.addResourceBatch(urls, function() { done(); }); // Make sure it works at all - single batch calls successful "done" callback
        var fakeLoader = loader.resources_loading[urls[0]].loader;

        // Now tell it the batch is finished to invoke the "complete" handler
        fakeLoader.completeFakeLoad(urls);
    });
});
