#!/bin/bash

set -e
set -x

which mocha-headless-chrome || npm install -g mocha-headless-chrome

./node_modules/.bin/webpack --config test/js/webpack.config.js

pushd test/js/test_server
rackup -p 6543 &
sleep 1
popd

#open -a "Google Chrome.app" test/js/test_server/mocha_tests.html
#mocha-headless-chrome -f test/js/test_server/mocha_tests.html
mocha-headless-chrome -f http://localhost:6543/mocha_tests.html

# Now get rid of that Sinatra server
kill %1
