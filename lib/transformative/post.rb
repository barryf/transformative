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
        hash[property] = value
      end
      hash
    end

    def to_hash
      hash = {}
      valid_properties.each do |property|
        value = self.send(property)
        next if value.nil? || value.empty?
        hash[property] = value
      end
      hash
    end

    def replace_property(property, value)
      return unless valid_property?(property)
      current_value = self.send(property)
      # unwrap single-value arrays if not array
      if !current_value.is_a?(Array) && value.size == 1
        value = value[0]
      end
      self.send("#{property}=", value)
    end

    def add_property(property, value)
      return unless valid_property?(property)
      current_value = self.send(property)
      # if property is an array append to it
      if current_value.is_a?(Array)
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

    def remove_property(property, value)
      return unless valid_property?(property)
      current_value = self.send(property)
      # if property is an array remove from it
      if current_value.is_a?(Array)
        self.send("#{property}=", current_value - value)
      end
    end

    def set_property(property, value)
      property = hyphens_to_underscores(property)
      return unless valid_property?(property)
      new_value = array_properties.include?(property) ? value : value[0]
      self.send("#{property}=", new_value)
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
      properties_without_content = to_hash
      properties_without_content.delete('content')
      "#{properties_without_content.to_yaml}---\n#{content}"
    end

    def set_timestamps
      now = Time.now.utc
      @published ||= now
      @updated = now
    end

    def self.exists_by_url?(url)
      # TODO
      true
    end

    def self.find_by_url(url)
      p = Entry.new
      p.published = Time.now
      p.category = ["one","two"]
      p.content = "My content"
      p.name = "My name"
      p.in_reply_to = "https://test"
      p.syndication = ["https://twitter.com/barryf/status/768401483448496128"]
      p
    end

  end
end