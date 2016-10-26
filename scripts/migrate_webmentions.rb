require 'yaml'
require 'time'
require 'json'
require 'jekyll'

path_moof = "/Users/barry/data-2016-10-22/webmentions"
path_new  = "/Users/barry/Dropbox/barryfrost.com/content/cites"
path_card = "/Users/barry/Dropbox/barryfrost.com/content/cards"

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

  post_url = "https://barryfrost.com#{data['post_permalink']}"
  case data['webmention_type']
  when 'reply'
    properties['in-reply-to'] = [post_url]
  when 'repost'
    properties['repost-of'] = [post_url]
  when 'like'
    properties['like-of'] = [post_url]
  when 'mention'
    properties['mention-of'] = [post_url]
  end

  if data.key?('photo')
    properties['photo'] = [data['photo']]
  end

  if data.key?('author_url')
    if data['author_url'].start_with?('https://twitter.com')
      properties['author'] = [data['author_url'].split('/')[0..3].join('/')]
    else
      properties['author'] = [data['author_url']]
    end
  else
    properties['author'] = [data['author']]
  end

  # create card
  card_slug = Jekyll::Utils.slugify(properties['author'][0])
  next if card_slug.nil?
  card_slug = card_slug.gsub!('-','/')
  cp = {}
  cp['name'] = [data['author_name']] if data.key?('author_name')
  cp['photo'] = [data['author_photo']] if data.key?('author_photo')
  cp['url'] = [data['author_url']] if data.key?('author_url')
  card_content = JSON.pretty_generate({
    type: ['h-card'],
    properties: cp
  })
  filename = "#{path_card}/#{card_slug}.json"
  FileUtils.mkdir_p(File.dirname(filename))
  File.write(filename, card_content)

  # create cite
  slug = Jekyll::Utils.slugify(data['url'])
  next if slug.nil?
  slug.gsub!('-','/')
  file_content = JSON.pretty_generate({
    type: ['h-cite'],
    properties: properties
  })
  filename = "#{path_new}/#{slug}.json"
  FileUtils.mkdir_p(File.dirname(filename))
  File.write(filename, file_content)

end
