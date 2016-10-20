$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = ENV['RACK_ENV'].to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load

# automatically parse json in the body
use Rack::PostBodyContentTypeParser

require 'microformats'
require 'transformative'
run Transformative::Server
