module Transformative
  class Post

    STATUSES = %i( live draft deleted ).freeze
    attr_reader :status

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

    def post_object
      self.class.name.split('::').last.downcase
    end

    def mf2_object
      "h-#{post_object}"
    end

    def to_mf2(properties=valid_properties)
      hash = {}
      properties.each do |property|
        next unless valid_properties.include?(property)
        value = self.send(property)
        next if value.nil? || value.empty?
        value = [value] unless value.is_a?(Array)
        hash[underscores_to_hyphens(property)] = value
      end
      hash
    end

    def to_yaml_front_matter
      hash = {}
      valid_properties.each do |property|
        value = self.send(property)
        next if value.nil? || value.empty?
        hash[property] = value
      end
      # front matter shouldn't have the content: it's appended below
      hash.delete('content')
      hash.to_yaml
    end

    def set(properties)
      properties.each do |property|
        set_property(property[0], property[1])
      end
    end
    def set_property(property, value)
      property = hyphens_to_underscores(property)
      return unless valid_property?(property)
      #new_value = array_properties.include?(property) ? value : value[0]
      self.send("#{property}=", value)
    end

    def replace(properties)
      properties.each do |property|
        replace_property(property[0], property[1])
      end
    end
    def replace_property(property, value)
      property = hyphens_to_underscores(property)
      return unless valid_property?(property)
      current_value = self.send(property)
      # unwrap single-value arrays if not array
      new_value = array_properties.include?(property) ? value : value[0]
      self.send("#{property}=", new_value)
    end

    def add(properties)
      properties.each do |property|
        add_property(property[0], property[1])
      end
    end
    def add_property(property, value)
      property = hyphens_to_underscores(property)
      return unless valid_property?(property)
      current_value = self.send(property)
      # if property is an array append to it
      if array_properties.include?(property)
        # if this value already exists in the array then ignore
        return if current_value.include?(value)
        self.send("#{property}=", current_value + value)
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
        remove_property(property[0], property[1])
      end
    end
    def remove_property(property, value)
      property = hyphens_to_underscores(property)
      return unless valid_property?(property)
      current_value = self.send(property)
      # if property is an array remove from it
      if array_properties.include(property)
        self.send("#{property}=", current_value - value)
      else
        # non-array property
        self.send("#{property}=", nil)
      end
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
      valid_properties.include?(property)
    end

    def file_name_with_path
      published_date = Time.parse(published)
      "/#{post_object}/#{published_date.strftime('%Y/%m')}/#{slug}.txt"
    end

    def file_content
      yaml = to_yaml_front_matter
      "#{yaml}---\n#{content}"
    end

    def set_timestamp(action)
      now = Time.now.utc
      case action
      when :create
        @published ||= now
      else
        @updated = now
      end
    end

    def self.exists_by_url?(url)
      # TODO
      true
    end

    def self.find_by_url(url)
      p = Entry.new
      p.published = Time.parse '2016-09-17T21:11:14Z'
      p.category = ["one","two"]
      p.content = "My content"
      p.name = "My name"
      p.in_reply_to = "https://test"
      p.syndication = ["https://twitter.com/barryf/status/768401483448496128"]
      p
    end

  end
end