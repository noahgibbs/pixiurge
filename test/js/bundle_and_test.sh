#!/bin/bash

set -e
set -x

./node_modules/.bin/webpack --config test/js/webpack.config.js
#ruby test/js/test_server/server.rb &  # Run the Sinatra server for the tests
open -a "Google Chrome.app" test/js/test_server/mocha_tests.html
