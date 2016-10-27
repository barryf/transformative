# for local development and testing, fake the github api
module Transformative
  class FileSystem

    def contents(repo, opts)
      path = File.join(content_path, opts[:path])
      begin
        content = File.read(path)
      rescue
        return
      end
      content_encoded = Base64.encode64(content)
      OpenStruct.new({
        'content' => content_encoded,
        'sha' => 'fake_sha'
      })
    end

    def create_contents(repo, filename, message, content)
      path = File.join(content_path, filename)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    def update_contents(repo, filename, message, sha, content)
      create_contents(repo, filename, message, content)
    end

    def upload(filename, file)
      path = File.join(content_path, filename)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, file)
    end

    def content_path
      "#{File.dirname(__FILE__)}/../../../content"
    end

  end
end