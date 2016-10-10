require 'yaml'

module Transformative
  class Post

    STATUSES = %i( live draft deleted ).freeze

    def initialize(microformat_object)
      @object = microformat_object
    end

    def object
      @object
    end

    def status
      @status || :live
    end

    def slug
      Random.new_seed.to_s
    end

    def url
      # TODO
      "/"
    end

    def to_mf2(properties=@object.class.valid_properties)
      hash = {}
      properties.each do |property|
        next unless @object.class.valid_properties.include?(property)
        value = @object.send(property)
        next if value.nil? || value.empty?
        value = [value] unless value.is_a?(Array)
        hash[underscores_to_hyphens(property)] = value
      end
      hash
    end

    def class_name
      @object.class.class_name
    end

    def mf2_name
      @object.class.mf2_name
    end

    def to_yaml_front_matter
      hash = {}
      @object.class.valid_properties.each do |property|
        value = @object.send(property)
        next if value.nil? || value.empty?
        hash[property] = value
      end
      # front matter shouldn't have the content: it's appended after
      hash.delete('content')
      hash.to_yaml
    end

    def mf2_to_front_matter!(hash)
      hash[:title] = hash.delete(:name)
      hash[:tags] = hash.delete(:category)
    end

    def front_matter_to_mf2!(hash)
      hash[:name] = hash.delete(:title)
      hash[:category] = hash.delete(:tags)
    end

    def parse_file(file, klass)
      parts = file.split(/---\n/)
      front_matter = YAML.load(parts[1])
      front_matter_to_mf2!(front_matter)

      object = klass.new
      post = Post.new(object)
      object.content = parts[2] unless parts[2].empty?

      klass.valid_properties.each do |property|
        if front_matter.key?(property) && !front_matter[property].empty?
          object.send("#{property}=", front_matter[property])
        end
      end

      post
    end

    def set(properties)
      properties.each do |property|
        set_property(property[0], property[1])
      end
    end
    def set_property(property, value)
      property = hyphens_to_underscores(property)
      return unless @object.class.valid_property?(property)
      new_value = @object.class.array_properties.include?(property) ?
        value : value[0]
      @object.send("#{property}=", new_value)
    end

    def replace(properties)
      properties.each do |property|
        replace_property(property[0], property[1])
      end
    end
    def replace_property(property, value)
      property = hyphens_to_underscores(property)
      return unless @object.class.valid_property?(property)
      current_value = @object.send(property)
      # unwrap single-value arrays if not array
      new_value = @object.class.array_properties.include?(property) ?
        value : value[0]
      @object.send("#{property}=", new_value)
    end

    def add(properties)
      properties.each do |property|
        add_property(property[0], property[1])
      end
    end
    def add_property(property, value)
      property = hyphens_to_underscores(property)
      return unless @object.class.valid_property?(property)
      current_value = @object.send(property)
      # if property is an array append to it
      if @object.class.array_properties.include?(property)
        # if this value already exists in the array then ignore
        return if current_value.include?(value)
        @object.send("#{property}=", current_value + value)
      else
        # non-array property
        # if property already exists then ignore
        return unless current_value.nil? || current_value.empty?
        # this property is brand new so use replace function
        replace_property(property, value)
      end
    end

    def remove(properties)
      properties.each do |property|
        remove_property(property)
      end
    end
    def remove_property(property)
      property = hyphens_to_underscores(property)
      return unless @object.valid_property?(property)
      @object.send("#{property}=", nil)
    end

    def delete
      @status = :deleted
    end

    def undelete
      @status = :live
    end

    def hyphens_to_underscores(name)
      name.gsub('-','_')
    end

    def underscores_to_hyphens(name)
      name.gsub('_', '-')
    end

    def valid_property?(property)
      @object.valid_properties.include?(property)
    end

    def file_name_with_path
      case class_name.to_sym
      when :card
        @object.url
      when :cite
        @object.url
      when :entry
        published_date = Time.parse(@object.published)
        "/#{class_name}/#{published_date.strftime('%Y/%m')}/#{slug}.md"
      when :event
        @object.url
      else
        # TODO: raise something bad
      end
    end

    def file_content
      yaml = to_yaml_front_matter
      if %w( entry cite ).include?(class_name)
        "#{yaml}---\n#{@object.content}"
      else
        yaml
      end
    end

    def set_timestamp(action)
      now = Time.now.utc
      case action
      when :create
        @object.published ||= now if @object.respond_to?(:published)
      else
        @object.updated = now if @object.respond_to?(:updated)
      end
    end

    def syndicate(services)
      # only syndicate if the object supports it
      return unless @object.respond_to?('syndication')

      new_syndications = []
      # iterate over the mp-syndicate-to services
      services.each do |service|
        new_syndications << Syndication.send(self, service)
      end

      unless new_syndications.empty?
        # add to syndications list
        @object.syndication.merge!(new_syndications)
        Store.put_post(self)
      end
    end

    def self.exists_by_url?(url)
      # TODO
      true
    end

    def self.find_by_url(url)
      e = Microformats::Entry.new
      e.published = Time.parse '2016-09-17T21:11:14Z'
      e.category = ["one","two"]
      e.content = "My content"
      e.name = "My name"
      e.in_reply_to = "https://test"
      e.syndication = ["https://twitter.com/barryf/status/768401483448496128"]
      e
      Post.new(e)
    end

  end
end