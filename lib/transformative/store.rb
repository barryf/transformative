module Transformative
  module Store
    module_function

    def put_post(post)
      put(post.file_name_with_path, post.class_name, post.file_content)
    end

    def put(filename, type, content)
      client.create_contents(
        github_full_repo,
        filename,
        "Adding new #{type} using Transformative.",
        content
      )
    end

    def process_build(params)
      require_built_build(params)
      commit = get_commit(params['build']['commit'])
      posts = []
      commit['files'].each do |file|
        filename = file['filename']
        next unless filename.start_with?('_posts/')
        file_content = get_file_content(filename)
        post = parse_file(file_content, Microformats::Entry)
        posts << post
      end
      posts
    end

    private

    def require_built_build(params)
      unless params.has_key?('build') && params['build'].has_key?('status') &&
          params['build']['status'] == 'built'
        raise StoreError.new(
          "Request must contain successful GitHub Pages build payload.")
      end
    end

    def get_file_content(filename)
      base64_content = octokit.contents(
        github_full_repo,
        { path: filename }
      ).content
      Base64.decode64(base64_contents)
    end

    def github_full_repo
      "#{ENV['GITHUB_USER']}/#{ENV['GITHUB_REPO']}"
    end

    def client
      @octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    end

  end

  class StoreError < RequestError
    def initialize(message)
      super("store", message)
    end
  end

end