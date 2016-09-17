module Transformative
  module Store
    module_function

    def client
      @octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    end

    def save_github(post)
      client.create_contents(
        ENV['GITHUB_REPO'],
        post.file_name_with_path,
        "Adding new #{post.post_object} using Transformative.",
        post.file_content)
    end

    def save(post)
      #File.open(post.file_name_with_path, 'w') do |file|
      #  file.write(post.file_content)
      #end
      puts "SAVE: #{post.file_name_with_path} #{post.file_content}"
    end

  end
end