ENV['RACK_ENV'] = 'test'

#Bundler.setup

require "pixiurge/config_ru"
require "minitest"
require "rack/test"

class ConfigRuTest < Minitest::Test
  include Rack::Test::Methods

  def test_nothing_useful
    assert_equal true, true
  end

  def app
    #@@my_app ||= Rack::Builder.parse_file("config.ru").first
    @@my_app ||= Rack::Builder.new_from_string(File.read(File.join(__dir__, "data", "my_app_config.ru")), "my_app_config.ru")
  end

  def test_can_serve_dev_pixiurge
    get '/pixiurge/pixiurge.js'
    assert last_response.ok?
    #assert_equal "Bobo", last_response.body
  end

  #def test_it_says_hello_world
  #  browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
  #  browser.get '/'   # get url, req_params, rack_env   # For Rack env, see http://www.rubydoc.info/github/rack/rack/master/file/SPEC
  #  assert browser.last_response.ok?
  #  assert_equal 'Hello World', browser.last_response.body
  #end
end
