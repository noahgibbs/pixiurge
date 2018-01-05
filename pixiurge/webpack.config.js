const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
//const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

const pixiurge_source_files = glob.sync("pixiurge/pixiurge*.coffee").concat(glob.sync("vendor/dev/*.js")).map(function(d) { return path.resolve(__dirname + "/..", d); });

module.exports = {
    context: __dirname + "/..",
    target: "web",
    entry: {
        "pixiurge-combined": pixiurge_source_files,
        "pixiurge-combined.min": pixiurge_source_files
    },
    devtool: "source-map",
    output: {
        path: path.resolve(__dirname, "../releases"),
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
