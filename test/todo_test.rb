ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../todo"

class TodoTest < Minitest::Test
  include Rack::Test::Methods
  
  def app 
    Sinatra::Application
  end
  
  def test_hello_world
    get "/hello_world"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Hello, world!", last_response.body
  end
end