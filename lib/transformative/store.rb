module Transformative
  module Store
    module_function

    def save(post)
      # ensure entry posts always have an entry-type
      if post.type == 'h-entry'
        post.properties['entry-type'] ||= [post.entry_type]
      end
      put(post.filename, post.data)
      post
    end

    def put(filename, data)
      content = JSON.pretty_generate(data)
      if sha = exists?(filename)
        update(sha, filename, content)
      else
        create(filename, content)
      end
    end

    def create(filename, content)
      octokit.create_contents(
        github_full_repo,
        filename,
        "Adding new post using Transformative.",
        content
      )
    end

    def update(sha, filename, content)
      octokit.update_contents(
        github_full_repo,
        filename,
        "Updating post using Transformative.",
        sha,
        content
      )
    end

    def get(filename)
      file_content = get_file_content(filename)
      data = JSON.parse(file_content)
      url = filename.sub(/\.json$/, '')
      Post.new(url, data['type'][0], data['properties'])
    end

    def get_url(url)
      relative_url = Utils.relative_url(url)
      get("#{relative_url}.json")
    end

    def exists?(filename)
      file = get_file(filename)
      unless file.nil?
        file['sha']
      end
    end

    def exists_url?(url)
      relative_url = Utils.relative_url(url)
      exists?("#{relative_url}.json")
    end

    def get_file(filename)
      begin
        octokit.contents(github_full_repo, { path: filename })
      rescue Octokit::NotFound
      end
    end

    def get_file_content(filename)
      base64_content = octokit.contents(
        github_full_repo,
        { path: filename }
      ).content
      Base64.decode64(base64_content)
    end

    def github_full_repo
      "#{ENV['GITHUB_USER']}/#{ENV['GITHUB_REPO']}"
    end

    def octokit
      @octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    end

  end

  class StoreError < TransformativeError
    def initialize(message)
      super("store", message)
    end
  end

end