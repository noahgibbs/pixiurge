ENV['RACK_ENV'] = 'test'

require "pixiurge"
require "minitest"
require "rack/test"

class AuthTest < Minitest::Test
  include Rack::Test::Methods

  APP_TEXT = <<TEXT
require "pixiurge/config_ru"

class AuthTestApp < Pixiurge::App
end

# Why is this important? Because this sets nearly nothing except a
# Rack builder and a root dir, so we should make sure we can serve
# requests at all. For a more complex example that sets more asset
# directories, see the config.ru test.

# When would you use a real setup like this? Most obviously when you
# run a Ruby server that doesn't serve even the index.html and *only*
# acts as a Websocket server, which is totally fine. This
# will set up a non-Websocket server as well, but it will always
# return 404 for any file - no asset directories or files get set up,
# so none will be served.

app = AuthTestApp.new
app.rack_builder self
app.root_dir __dir__
TEXT
  def app
    @@my_app ||= Rack::Builder.parse_file(File.join(__dir__, "data", "my_app_config.ru")).first
  end

  # Though the server should still do the automatic serving of Pixiurge itself...
  def test_can_serve_pixiurge_js
    get '/pixiurge/pixiurge.js'
    assert last_response.ok?
    assert last_response.body["Pixiurge"]
  end

end
