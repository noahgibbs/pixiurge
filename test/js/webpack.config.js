const path = require('path');
const glob = require('glob');

module.exports = {
    context: __dirname + "/../..",
    target: "web",

    entry: glob.sync("./test/js/*test.js")
    .concat(glob.sync("./vendor/dev/*.js"))
    .concat(glob.sync("./test/jshelper/*.js"))
    .concat([
             // Include modular, un-minified Pixiurge to test latest changes
             "./pixiurge/pixiurge.coffee",
             "./pixiurge/pixiurge_websocket.coffee",
             "./pixiurge/pixiurge_display.coffee"
            ]),
    output: {
        filename: "test/js/test_server/test_bundle.js"
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
    }
};
