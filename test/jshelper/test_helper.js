window.TestHelper = {
    // Verify that all loads have finished on a Pixiurge.Loader object
    verifyAllLoaded: function(loader) {
        loading = loader.resourcesLoading;
        for(var key in loading) {
            console.log("Unexpected 'loading' key in loader: " + key + "!");
        }
        if(Object.keys(loading).length != 0) {
            return false;
        }
        return true;
    },
    dummyValue: {}
};
