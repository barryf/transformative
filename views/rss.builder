xml.instruct! :xml, version: '1.0'
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Barry Frost"
    xml.description "Barry Frost's feed."
    xml.link ENV['SITE_URL']

    xml.link rel: "hub", href: ENV['PUBSUBHUBBUB_HUB']
    xml.link rel: "self", href: "#{ENV['SITE_URL']}rss"
    xml.link rel: "alternate", href: ENV['SITE_URL']

    @posts.each do |post|
      xml.item do
        xml.title post.properties['name'][0] if post.properties.key?('name')
        xml.link post.properties['entry-type'][0] == 'bookmark' ?
          post.properties['bookmark-of'][0] :
          "#{URI.join(ENV['SITE_URL'], post.url)}"
        xml.description rss_description(post)
        xml.pubDate Time.parse(post.properties['published'][0]).rfc822()
        xml.guid "#{URI.join(ENV['SITE_URL'], post.url)}"
      end
    end
  end
end
