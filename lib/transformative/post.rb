module Transformative
  class Post

    PROPERTIES = %i( name content published slug category ).freeze
    PROPERTIES.each { |p| attr_accessor p }

    STATUSES = %i( live draft deleted ).freeze
    attr_accessor :status
    
    def category
      @category || []
    end

    def status
      @status || :live
    end

    def slug
      # TODO
      @slug || "slug"
    end

    def permalink
      published = @published || Time.now.utc
      "/#{Time.parse(published.to_s).strftime('%Y/%m')}/#{@slug}"
    end

    def save!
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
    
    def valid_property?(property)
      unless PROPERTIES.include?(property) 
        puts "Did not recognise property '#{property}'"
        # don't throw, it's ok if we don't know about a property
        return
      end
      true
    end
    
    def delete
      @status = :deleted
      save!
    end
    
    def undelete
      @status = :live
      save!
    end
    
    def self.statuses
      STATUSES
    end

    def self.exists_by_url?(url)
      # TODO
      true
    end
    
    def self.find_by_url(url)
      Post.new
    end

  end
end