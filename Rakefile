# create table posts (url varchar(255) primary key, data jsonb);

require "bundler/setup"
Bundler.require(:default, :development)

require 'json'
require 'time'

require 'dotenv'
Dotenv.load

DB = Sequel.connect(ENV['DATABASE_URL'])
DB[:posts].truncate

CONTENT_PATH = "#{File.dirname(__FILE__)}/../content"

def parse(file)
  data = File.read(file)
  post = JSON.parse(data)
  url = file.sub(CONTENT_PATH,'').sub(/\.json$/,'')

  DB[:posts].insert(url: url, data: data)

  print "."
end

desc "Rebuild database cache from all content JSON files."
task :rebuild do
  Dir.glob("#{CONTENT_PATH}/**/*.json").each do |file|
    parse(file)
  end
end

desc "Rebuild database cache from this month's content JSON files."
task :recent do
  year_month = Time.now.strftime('%Y/%m')
  files = Dir.glob("#{CONTENT_PATH}/#{year_month}/**/*.json")
  # need to rebuild all cites and cards because they're not organised by month
  files += Dir.glob("#{CONTENT_PATH}/cite/**/*.json")
  files += Dir.glob("#{CONTENT_PATH}/card/**/*.json")
  files.each do |file|
    parse(file)
  end
end
