//const path = require('path');
const glob = require('glob');
//const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

//const pixiurge_source_files = glob.sync("pixiurge*.coffee").concat(glob.sync("../vendor/dev/*.js"));

module.exports = {
    context: __dirname,
    target: "web",
    entry: {
        "pixiurge-combined": glob.sync("pixiurge*.coffee").concat(glob.sync("../vendor/dev/*.js")),
        "pixiurge-combined.min": glob.sync("pixiurge*.coffee").concat(glob.sync("../vendor/dev/*.js"))
    },
    //devtool: "source-map",
    output: {
        path: "../releases",
        filename: "[name].js"
    },
    module: {
        loaders: [
          { test: /\.coffee$/, loader: "coffee-loader" }
        ]
    },
    resolve: {
        modules: [
                  "node_modules"
        ],
        extensions: [".web.coffee", ".web.js", ".coffee", ".js"],
        symlinks: true
    },
    plugins: [
              new webpack.optimize.UglifyJsPlugin({
                      include: /\.min\.js$/,
                      minimize: true
                  })
    ]
};
