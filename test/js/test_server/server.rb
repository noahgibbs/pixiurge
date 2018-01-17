require "sinatra"

# This little server hosts the test JS file and source map

get "/" do
  "<h1>Pixiurge JS Testing Server is Live</h1>\n<p>May I recommend the URL /mocha_tests.html?</p>"
end

get "/mocha_tests.html" do
  File.read("mocha_tests.html")
end

post "/test_results" do
end
