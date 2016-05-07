$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "bundler/setup"
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

# automatically parse json in the body
use Rack::PostBodyContentTypeParser

require 'transformative'
run Transformative::Server
