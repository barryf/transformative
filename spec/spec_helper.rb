$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "bundler/setup"
Bundler.require(:default, :test)

require 'rack/test'
require 'transformative'
require 'rspec'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Transformative::Server
  end
end

RSpec.configure { |c| c.include RSpecMixin }
