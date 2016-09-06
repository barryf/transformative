module Transformative
  class Post

    STATUSES = %i( live draft deleted ).freeze
    attr_reader :status

    def status
      @status || :live
    end

    def post_object
      self.class.name.split('::').last.downcase
    end

    def mf2_object
      "h-#{post_object}"
    end

    def to_hash(properties=valid_properties)
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

    def delete
      @status = :deleted
    end

    def undelete
      @status = :live
    end

    def underscores_to_hyphens!(name)
      name.gsub!('_', '-')
    end

    def create_simple_value(property, params)
      underscores_to_hyphens!(property)
      if params.has_key?(property) && !params[property].empty?
        if params[property].is_a?(Array)
          params[property].first
        else
          params[property]
        end
      end
    end

    def create_array_value(property, params)
      underscores_to_hyphens!(property)
      if params.has_key?(property) && !params[property].empty?
        params[property]
      end
    end

    def valid_property?(property)
      valid_properties.include?(property)
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

  end
end