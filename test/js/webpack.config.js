const path = require('path');
const glob = require('glob');

module.exports = {
    context: __dirname + "/../..",
    target: "web",

    entry: glob.sync("./test/js/*test.js")
    .concat(glob.sync("./vendor/dev/*.js"))
    .concat(glob.sync("./pixiurge/pixiurge*.js").concat(glob.sync("./pixiurge/pixiurge*.coffee")).sort())
    .concat(glob.sync("./test/jshelper/*.js")),
    output: {
        filename: "test/js/test_server/public/test_bundle.js"
    },
    module: {
        loaders: [
          { test: /\.coffee$/, loader: "coffee-loader" }
        ]
    },
    devtool: "source-map",  // Generate source maps
    resolve: {
        modules: [
                  "node_modules"
        ],
        extensions: [".web.coffee", ".web.js", ".coffee", ".js"],
        symlinks: true
    },
    node: {  // This section is a fix for a source-map-support bug: https://github.com/evanw/node-source-map-support/issues/155
        fs: "empty",
        module: "empty"
    }
};
