require 'httparty'
require 'json'

SILOPUB_MICROPUB_ENDPOINT="https://silo.pub/micropub"
# barryfdata
SILOPUB_TWITTER_TOKEN="2b7c2e49ef2b17d3f663ff7f957ea5cb"

token = SILOPUB_TWITTER_TOKEN

body = {
  'h' => 'entry',
  'content' => "Testing from silo.pub 2"
}

headers = {
  'Authorization' => "Bearer #{token}"
}

response = HTTParty.post(
  SILOPUB_MICROPUB_ENDPOINT,
  body: body,
  headers: headers
)

hash = JSON.parse(response.body)
puts hash['id']