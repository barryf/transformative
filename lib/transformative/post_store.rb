# STORE IN GIT(HUB)? Rebase and cache in PG
# Edit the file in GH and then webhook sends update to T

module Transformative
  module PostStore
    module_function

    def save_file!(post)
      # set up and create directories if necessary
      file_path = "#{item_path}#{post.published.strftime('%Y/%m')}/"
      FileUtils.mkdir_p(file_path)

      slug = self.slug || self.published.strftime('%d-%H%M%S')
      file_name = "#{slug}.md"
      file_content = front_matter.to_s + "---\n" + self.content
      File.open(file_path + file_name, 'w') { |file| file.write(file_content) }
    end

    #def octokit
    #  @octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    #end

    def save(post)
      puts post.inspect
      #file_path = "#{post.post_object}/#{post.published.strftime('%Y/%m')}/"
      #file_name = "#{post.slug}.txt"
      #puts "Creating #{file_path}#{file_name}"
    end

  end
end