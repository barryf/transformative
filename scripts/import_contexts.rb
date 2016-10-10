require 'yaml'
require 'time'
require 'jekyll'

path_moof = "/Users/barry/data-2016-10-02/contexts"
path_new  = "/Users/barry/jekyll/_contexts"
path_card = "/Users/barry/jekyll/_cards"

Dir.glob("#{path_moof}/**/*.md").each do |file|

  puts "Reading #{file}"

  raw = File.read(file)
  raw_parts = raw.split(/---\n/)

  begin
    data = YAML.load(raw_parts[1])
  rescue
    puts raw
    raise
  end

  content = raw_parts[2].to_s

  post = {
    'context_url' => data['url'],
    'published' => Time.parse(data['published']).utc.iso8601.to_s,
    'slug' => Jekyll::Utils.slugify(data['url'])
  }

  if data.key?('photo')
    post['photo'] = data['photo']
  end


  # use correct url field
  if data['url'].start_with?('https://twitter.com')
    post['author'] = data['url'].split('/')[0..3].join('/')
  else
    post['author'] = data['author_url']
  end

  # create card
  card = { 'slug' => Jekyll::Utils.slugify(post['author']) }
  card['name'] = data['author_name'] if data.key?('author_name')
  card['photo'] = data['author_photo'] if data.key?('author_photo')
  card['card_url'] = data['author_url'] if data.key?('author_url')
  card_content = card.to_yaml.to_s + "---"
  File.write("#{path_card}/#{card['slug']}.md", card_content)


  file_content = post.to_yaml.to_s + "---\n" + content

  new_file = "#{path_new}/#{post['slug']}.md"

  FileUtils.mkdir_p( File.dirname(new_file) )

  #puts "Writing #{new_file}"

  File.write(new_file, file_content)

end
