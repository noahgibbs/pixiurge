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

  #def test_it_says_hello_world
  #  browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
  #  browser.get '/'   # get url, req_params, rack_env   # For Rack env, see http://www.rubydoc.info/github/rack/rack/master/file/SPEC
  #  assert browser.last_response.ok?
  #  assert_equal 'Hello World', browser.last_response.body
  #end
end
