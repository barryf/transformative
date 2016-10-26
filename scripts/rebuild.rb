# create table posts (url varchar(255) primary key, data jsonb);

require "bundler/setup"
Bundler.require(:default, :development)

require 'json'
require 'time'

require 'dotenv'
Dotenv.load

DB = Sequel.connect(ENV['DATABASE_URL'])

# delete all rows
DB[:posts].truncate

path = "#{File.dirname(__FILE__)}/../../content"

Dir.glob("#{path}/**/*.json").each do |file|

  data = File.read(file)
  post = JSON.parse(data)

  url = file.sub(path,'').sub(/\.json$/,'')

  DB[:posts].insert(url: url, data: data)

  print "."

end
