source 'https://rubygems.org'

ruby '2.3.1'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'rack-contrib'
gem 'puma'
gem 'httparty'
gem 'nokogiri'
gem 'octokit'
gem 'microformats2'
gem 'redcarpet'
gem 'sanitize'
gem 'builder'
gem 'webmention', git: 'https://github.com/indieweb/mention-client-ruby'
gem 'sequel_pg', require: 'sequel'
gem 'will_paginate'
gem 's3'

group :production do
  gem 'sentry-raven'
end

group :development do
  gem 'dotenv'
  gem 'shotgun'
  gem 'guard'
  gem 'guard-rspec'
  gem 'pry'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
end