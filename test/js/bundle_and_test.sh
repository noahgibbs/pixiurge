#!/bin/bash

set -e
set -x

which mocha-headless-chrome || npm install -g mocha-headless-chrome

./node_modules/.bin/webpack --config test/js/webpack.config.js

# Old test server running? Kill it.
kill `ps | grep "rackup" | grep "6543" | cut -d " " -f 1` || echo "No kill, no problem."

pushd test/js/test_server
rackup -p 6543 &
sleep 1
curl http://localhost:6543 || echo "Not up yet..."
popd

#open -a "Google Chrome.app" test/js/test_server/mocha_tests.html
#mocha-headless-chrome -f test/js/test_server/mocha_tests.html
mocha-headless-chrome -f http://localhost:6543/mocha_tests.html
#open -a "Google Chrome.app" http://localhost:6543/mocha_tests.html

# Now get rid of that test web server
kill `ps | grep "rackup" | grep "6543" | cut -d " " -f 1` || echo "No kill, no problem."
