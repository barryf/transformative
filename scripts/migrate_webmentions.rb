require 'yaml'
require 'time'
require 'json'
require 'jekyll'

path_moof = "/Users/barry/data-2016-10-02/webmentions"
path_new  = "/Users/barry/Desktop/json/cites"
path_card = "/Users/barry/Desktop/json/cards"
path_wm   = "/Users/barry/Desktop/json/webmentions"

Dir.glob("#{path_moof}/**/*.md").each do |file|

  puts "Reading #{file}"

  raw = File.read(file)
  raw_parts = raw.split(/---\n/)

  properties = {}
  properties['content'] = [raw_parts[2].to_s] unless raw_parts[2].to_s.empty?

  begin
    data = YAML.load(raw_parts[1])
  rescue
    puts raw
    raise
  end

  properties = {
    'url' => [data['url']],
    'published' => [Time.parse(data['published']).utc.iso8601.to_s],
  }

  content = raw_parts[2].to_s
  unless content.empty?
    properties['content'] = [content]
  end

  #post_url = "https://barryfrost.com#{data['post_permalink']}"

  if data.key?('photo')
    properties['photo'] = [data['photo']]
  end

  if data['url'].start_with?('https://twitter.com')
    properties['author'] = [data['url'].split('/')[0..3].join('/')]
  else
    properties['author'] = [data['author_url']]
  end

  # create card
  card_slug = Jekyll::Utils.slugify(properties['author'][0])
  cp = {}
  cp['name'] = [data['author_name']] if data.key?('author_name')
  cp['photo'] = [data['author_photo']] if data.key?('author_photo')
  cp['url'] = [data['author_url']] if data.key?('author_url')
  card_content = {
    type: ['h-card'],
    properties: cp
  }.to_json
  File.write("#{path_card}/#{card_slug}.json", card_content)

  # create cite
  slug = Jekyll::Utils.slugify(data['url'])
  file_content = {
    type: ['h-cite'],
    properties: properties
  }.to_json
  File.write("#{path_new}/#{slug}.json", file_content)

  # create webmention file
  wm_slug = "#{data['post_permalink']}/#{slug}"
  wm_content = {
    source: data['url'],
    target: "https://barryfrost.com#{data['post_permalink']}",
    method: data['webmention_type']
  }.to_json
  wm_file = "#{path_wm}#{wm_slug}.json"
  FileUtils.mkdir_p( File.dirname(wm_file) )
  File.write(wm_file, wm_content)

end
