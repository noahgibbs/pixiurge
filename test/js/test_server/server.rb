require "sinatra"

# This little server hosts the test JS file and source map

get "/" do
  "<h1>Pixiurge JS Testing Server is Live</h1>\n<p>May I recommend the URL /mocha_tests.html?</p>"
end

get "/test_bundle.js" do
  File.read(__dir__ + "/test_bundle.js")
end

get "/test_bundle.js.map" do
  File.read(__dir__ + "/test_bundle.js.map")
end

get "/mocha_tests.html" do
  File.read("mocha_tests.html")
end

post "/test_results" do
end
