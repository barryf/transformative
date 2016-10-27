$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = ENV['RACK_ENV'].to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load unles env == :production

# automatically parse json in the body
use Rack::PostBodyContentTypeParser

require 'will_paginate/sequel'
Sequel::Database.extension(:pagination)
Sequel.extension(:pg_array, :pg_json, :pg_json_ops)

require 'transformative'
run Transformative::Server
