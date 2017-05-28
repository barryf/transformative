module Transformative
  module Authorship
    module_function

    def fetch(url)
      return unless Utils.valid_url?(url)
      get_author(url)
    end

    def get_author(url)
      json = Microformats.parse(url).to_json
      items = JSON.parse(json)['items']

      # find first h-entry
      entry = find_first_hentry(items)
      if entry.nil?
        raise AuthorshipError.new("No h-entry found at #{url}.")
      end

      # find author in the entry or on the page
      author = find_author(entry, url)
      return if author.nil?

      # find author properties
      if author.is_a?(Hash) && author['type'][0] == 'h-card'
        Card.new(author['properties'])
      elsif author.is_a?(String)
        url = if Utils.valid_url?(author)
            author
          else
            begin
              URI.join(url, author).to_s
            rescue URI::InvalidURIError
            end
          end
        get_author_hcard(url) if url
      end
    end

    def find_first_hentry(items)
      items.each do |item|
        if item['type'][0] == 'h-entry'
          return item
        end
      end
    end

    def find_author(entry, url)
      body = HTTParty.get(url).body
      if entry.is_a?(Hash) && entry['properties'].key?('author')
        entry['properties']['author'][0]
      elsif author_rel = Nokogiri::HTML(body).css("[rel=author]")
        author_rel.attribute('href').value
      end
    end

    def get_author_hcard(url)
      json = Microformats.parse(url).to_json
      properties = JSON.parse(json)['items'][0]['properties']
      # force the url to be this absolute url
      properties['url'] = [url]
      Card.new(properties)
    end

  end
end