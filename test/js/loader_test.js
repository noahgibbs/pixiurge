const assert = require('assert');

describe('Pixiurge loader', function() {
    describe('configured with no failures, single batch', function() {
        it('should call back successfully', function(done) {
            // Create a new Pixiurge loader with a mocked PIXI.loaders.Loader class behind it
            var loader = new window.Pixiurge.Loader(window.Mock.MockLoader);

            var urls = ["https://fake_url_1/fake.png", "https://fake_url_2/fake.json"];
            loader.addResourceBatch(urls, function() { done(); }); // Make sure it works at all - single batch calls successful "done" callback
            var fakeLoader = loader.resources_loading[urls[0]].loader;

            // Now tell it the batch is finished to invoke the "complete" handler
            fakeLoader.completeFakeLoad(urls);
        });
    });

    describe('configured with no failures, semi-dependent batches', function() {
        it('should complete all batches', function() {
            // Create a new Pixiurge loader with a mocked PIXI.loaders.Loader class behind it
            var loader = new window.Pixiurge.Loader(window.Mock.MockLoader);

            // Four batches - batch 2 shares URLs with batch 1 an so depends on it
            // Batch four depends on batch 1 but not 2.
            var urls_1 = ["https://fake_url_1/fake.png", "https://fake_url_2/fake.json"];
            var urls_2 = ["https://fake_url_1/fake.png", "https://fake_url_2/fake.json", "https://fake_url_3/fake.json"];
            var urls_3 = ["https://fake_url_4/fake.json", "https://fake_url_5/fake.png"];
            var urls_4 = ["https://fake_url_1/fake.png"];
            var batch_1_complete = false;
            var batch_2_complete = false;
            var batch_3_complete = false;
            var batch_4_complete = false;
            loader.addResourceBatch(urls_1, function() { batch_1_complete = true });
            loader.addResourceBatch(urls_2, function() { batch_2_complete = true });
            loader.addResourceBatch(urls_3, function() { batch_3_complete = true });
            loader.addResourceBatch(urls_4, function() { batch_4_complete = true });

            var fakeLoader1 = loader.resources_loading[urls_1[0]].loader;
            var fakeLoader2 = loader.resources_loading[urls_2[2]].loader;
            var fakeLoader3 = loader.resources_loading[urls_3[0]].loader;
            var fakeLoader4 = loader.resources_loading[urls_4[0]].loader;

            // Mark batch 3 complete, which should be entirely independent of the others
            fakeLoader3.completeFakeLoad(urls_3);
            assert.equal(false, batch_1_complete);
            assert.equal(false, batch_2_complete);
            assert.equal(true, batch_3_complete);
            assert.equal(false, batch_4_complete);

            // Mark batch 2 as complete. Nothing new should show as done because batch 2 is waiting on batch 1.
            // Note: only pass the unique-to-batch-2 URLs through. The others count as dependent on batch 1, and it's not waiting for them.
            fakeLoader2.completeFakeLoad([urls_2[2]]);
            assert.equal(false, batch_1_complete);
            assert.equal(false, batch_2_complete);
            assert.equal(true, batch_3_complete);
            assert.equal(false, batch_4_complete);

            // Now mark batch 1 complete - batch 1, 2 and 4 should count as complete
            fakeLoader1.completeFakeLoad(urls_1);
            assert.equal(true, batch_1_complete);
            assert.equal(true, batch_2_complete);
            assert.equal(true, batch_3_complete);
            assert.equal(true, batch_4_complete);
        });
    });
});
