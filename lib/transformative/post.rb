module Transformative
  class Post

    def to_hash(properties=valid_properties)
      hash = {}
      properties.each do |property|
        next unless valid_properties.include?(property.to_sym)
        value = self.send(property.to_sym)
        next if value.nil? || value.empty?
        value = [value] unless value.is_a?(Array)
        hash[property] = value
      end
      hash
    end

    def slug
      # TODO
      @slug || "slug"
    end

    def permalink
      "/#{Time.parse(published.to_s).strftime('%Y/%m')}/#{slug}"
    end

    def replace_property(property, value)
      return unless self.valid_property?(property)
      current_value = self.send(property)
      # unwrap single-value arrays if not array
      if !current_value.is_a?(Array) && value.size == 1
        value = value[0]
      end
      self.send("#{property}=", value)
    end

    def add_property(property, value)
      return unless self.valid_property?(property)
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

    def delete
      @status = :deleted
    end

    def undelete
      @status = :live
    end

    def self.exists_by_url?(url)
      # TODO
      true
    end

    def self.find_by_url(url)
      p = Entry.new
      p.published = Time.now
      p.category = ["one","two"]
      p
    end

    def self.valid_property?(property)
      valid_properties.include?(property)
    end

  end
end