module Transformative
  module Cache
    module_function

    MAX_POSTS = 20

    def db
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
    end

    def row_to_post(row)
      klass = Post.class_from_type(row[:data]['type'][0])
      klass.new(row[:data]['properties'], row[:url])
    end

    def data
      Sequel.pg_jsonb_op(:data)
    end

    def put(post)
      json = post.data.to_json
      if db[:posts].where(url: post.url).count > 0
        db[:posts].where(url: post.url).update(data: json)
      else
        db[:posts].insert(url: post.url, data: json)
      end
    end

    def order_by_published_desc
      data['properties']['published'].get_text(0).desc
    end

    def get(url)
      row = db[:posts].where(url: url).first
      return if row.nil?
      klass = Post.class_from_type(row[:data]['type'][0])
      klass.new(row[:data]['properties'], url)
    end

    def get_json(url)
      data = db[:posts].where(url: url).first[:data]
      JSON.pretty_generate(data)
    end

    def get_by_properties_url(url)
      row = db[:posts].where(data['properties']['url'].get_text(0) => url).first
      return if row.nil?
      klass = Post.class_from_type(row[:data]['type'][0])
      klass.new(row[:data]['properties'], row[:url])
    end

    def get_first_by_slug(slug)
      db[:posts]
        .where(data['properties']['slug'].get_text(0) => slug)
        .map { |row| row_to_post(row) }
        .first
    end

    def find_via_syndication(syndication)
      db[:posts]
        .where(data['properties']['syndication'].contain_any(syndication))
        .map { |row| row_to_post(row) }
    end

    def authors_from_cites(*cites)
      author_urls = cites.compact.flatten.map do |cite|
        if cite.properties.key?('author') &&
            Utils.valid_url?(cite.properties['author'][0])
          cite.properties['author'][0]
        end
      end

      cards = db[:posts]
        .where(data['properties']['url'].get_text(0) => author_urls)
        .map { |row| row_to_post(row) }

      authors = {}
      cards.each do |card|
        authors[card.properties['url'][0]] = card
      end
      authors
    end

    def authors_from_categories(posts)
      author_urls = []
      Array(posts).each do |post|
        next unless post.properties.key?('category')
        post.properties['category'].each do |category|
          if Utils.valid_url?(category)
            author_urls << category
          end
        end
      end
      return {} if author_urls.empty?

      cards = db[:posts]
        .where(data['properties']['url'].get_text(0) => author_urls)
        .map { |row| row_to_post(row) }

      authors = {}
      cards.each do |card|
        authors[card.properties['url'][0]] = card
      end
      authors
    end

    def stream(types, page=1)
      db[:posts]
        .where(data['type'].get_text(0) => 'h-entry')
        .where(data['properties']['entry-type'].get_text(0) => types)
        .order(order_by_published_desc)
        .paginate(page.to_i, MAX_POSTS)
    end

    def stream_all(page=1, max=MAX_POSTS)
      db[:posts]
        .where(data['type'].get_text(0) => 'h-entry')
        .order(order_by_published_desc)
        .paginate(page.to_i, max.to_i)
    end

    def stream_tagged(tags, page=1)
      db[:posts]
        .where(data['type'].get_text(0) => 'h-entry')
        .where(data['properties']['category'].contain_all(tags.split('+')))
        .order(order_by_published_desc)
        .paginate(page.to_i, MAX_POSTS)
    end

    def stream_all_by_month(y, m)
      return unless Array(1..12).include?(m.to_i)
      return unless Array(2000..2050).include?(y.to_i)
      start_date = Date.new(y.to_i, m.to_i, 1)
      end_date = start_date.next_month
      db[:posts]
        .where(data['type'].get_text(0) => 'h-entry')
        .where(data['properties']['published'].get_text(0) =>
          (start_date..end_date))
        .order(order_by_published_desc)
    end

    def contexts(posts)
      posts = Array(posts)
      entry_type_property = {
        'reply' => 'in-reply-to',
        'repost' => 'repost-of',
        'like' => 'like-of',
        'rsvp' => 'in-reply-to'
      }
      urls = posts.map do |post|
        post.properties[entry_type_property[post.properties['entry-type'][0]]]
      end
      urls.flatten!

      cites = db[:posts]
        .where(data['type'].get_text(0) => 'h-cite')
        .where(data['properties']['url'].get_text(0) => urls)
        .order(data['properties']['published'].get_text(0))
        .map{ |row| row_to_post(row) }
    end

    def webmention_counts(posts)
      post_urls = posts.map { |post| post.absolute_url }

      replies = db[:posts]
        .where(data['properties']['in-reply-to'].contain_any(post_urls))
        .where(data['type'].get_text(0) => 'h-cite')
        .map { |row| row_to_post(row) }
      reposts = db[:posts]
        .where(data['properties']['repost-of'].contain_any(post_urls))
        .where(data['type'].get_text(0) => 'h-cite')
        .map { |row| row_to_post(row) }
      likes = db[:posts]
        .where(data['properties']['like-of'].contain_any(post_urls))
        .where(data['type'].get_text(0) => 'h-cite')
        .map { |row| row_to_post(row) }

      counts = {}
      posts.each do |post|
        counts[post.absolute_url] = { replies: 0, reposts: 0, likes: 0 }
      end
      replies.each do |reply|
        counts[reply.properties['in-reply-to'][0]][:replies] += 1
      end
      reposts.each do |repost|
        counts[repost.properties['repost-of'][0]][:reposts] += 1
      end
      likes.each do |like|
        counts[like.properties['like-of'][0]][:likes] += 1
      end
      counts
    end

    def webmentions(post)
      url = post.absolute_url
      db[:posts]
        .where(data['type'].get_text(0) => 'h-cite')
        .where(
            data['properties']['in-reply-to'].has_key?(url) |
            data['properties']['repost-of'].has_key?(url) |
            data['properties']['like-of'].has_key?(url) |
            data['properties']['mention-of'].has_key?(url)
        )
        .order(data['properties']['published'].get_text(0))
        .map{ |row| row_to_post(row) }
    end

  end
end
