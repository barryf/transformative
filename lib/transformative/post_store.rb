## Follow Moof and have storable and indexable for contexts, posts?

# STORE IN GIT(HUB)? Rebase and cache in PG
# Edit the file in GH and then webhook sends update to T

module Transformative
  module PostStore
    module_function

    def save!(post)
      # set up and create directories if necessary
      file_path = "#{item_path}#{post.published.strftime('%Y/%m')}/"
      FileUtils.mkdir_p(file_path)

      slug = self.slug || self.published.strftime('%d-%H%M%S')
      file_name = "#{slug}.md"
      file_content = front_matter.to_s + "---\n" + self.content
      File.open(file_path + file_name, 'w') { |file| file.write(file_content) }
    end

  end
end