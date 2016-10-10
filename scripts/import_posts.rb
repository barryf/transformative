require 'yaml'
require 'time'

path_moof = "/Users/barry/data-2016-10-02/posts"
path_new  = "/Users/barry/jekyll/_posts"

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
    'layout' => data['post_type']
  }

  data.keys.each do |key|
    case key
    when 'syndications'
      k = 'syndication'
    when 'bookmark'
      k = 'bookmark_of'
    when 'permalink', 'post_type', 'latitude', 'longitude'
      next
    else
      k = key
    end

    if %w( category syndication in_reply_to ).include?(k)
      post[k] = Array(data[key])
    else
      post[k] = data[key]
    end

    if k == 'published'
      post[k] = Time.parse(post[k]).utc.iso8601.to_s
    elsif k == 'photo'
      post[k] = "https://barryfrost.com/photos/" + post[k]
    end
  end

  file_content = post.to_yaml.to_s + "---\n" + content

  date = Time.parse(data['published']).utc
  permalink = date.strftime('/%Y/%m/%Y-%m-%d-') + data['slug']
  new_file = "#{path_new}#{permalink}.md"

  FileUtils.mkdir_p( File.dirname(new_file) )

  #puts "Writing #{new_file}"

  File.write(new_file, file_content)

end
