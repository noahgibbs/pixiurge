ENV['RACK_ENV'] = 'test'

#Bundler.setup

require "pixiurge/config_ru"
require "minitest"
require "rack/test"

class ConfigRuTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @@my_app ||= Rack::Builder.parse_file(File.join(__dir__, "data", "my_app_config.ru")).first
  end

  def test_can_serve_dev_pixiurge
    get '/pixiurge/pixiurge.js'
    assert last_response.ok?
    assert last_response.body["Pixiurge"]
  end

  def test_can_serve_static_files
    get '/bobo.txt'
    assert last_response.ok?
    assert_equal "Found the file", last_response.body.chomp
  end

  def test_can_serve_static_dirs
    get '/static/foo.js'
    assert last_response.ok?
    assert_equal "// Yup, it's a file.", last_response.body
  end

  def test_can_serve_coffeescript
    get '/coffee/tiny_coffee.js'
    assert last_response.ok?
    assert last_response.body["my_method"], "Make sure the CoffeeScript contains the right class method"
    assert last_response.body["function"], "Make sure the CoffeeScript is compiled to Javascript"
  end

  # Realistically, my JSON exporter isn't perfect. There are more
  # differences between TMX XML and JSON formats than I'm properly
  # accounting for. First, let's test the basic "convert TMX to JSON"
  # version.
  def test_can_serve_tmx_as_json
    get '/tmx/magecity_cc0_lorestrome.conv.json'
    assert last_response.ok?
    rack_exported_version = MultiJson.load(last_response.body)
    assert_equal 7, rack_exported_version["layers"].select { |l| l["type"] == "tilelayer" }.size
  end

  # This converts to a full TMX cache entry.
  def test_can_serve_tmx_as_cached_json
    get '/tmx/magecity_cc0_lorestrome.tmx.json'
    assert last_response.ok?
    rack_exported_version = MultiJson.load(last_response.body)
    assert_equal 7, rack_exported_version["map"]["layers"].select { |l| l["type"] == "tilelayer" }.size
  end

  # Realistically, my JSON exporter isn't perfect. There are more
  # differences between TMX XML and JSON formats than I'm properly
  # accounting for. First, let's test the basic "convert TMX to JSON"
  # version.
  def test_can_serve_tmx_as_manasource_cached_json
    get '/tmx/magecity_cc0_lorestrome.manasource.json'
    assert last_response.ok?
    rack_exported_version = MultiJson.load(last_response.body)
    assert rack_exported_version["collision"], "Parsed ManaSource-style TMX with a collision layer"
  end
end
