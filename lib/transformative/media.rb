module Transformative
  module Media
    module_function

    def save(file, dir='photo')
      filename = "#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex.to_s}"
      ext = file[:filename].match(/\./) ? '.' +
        file[:filename].split('.').last : ""
      filepath = "file/#{filename}#{ext}"
      content = file[:tempfile].read

      if ENV['RACK_ENV'] == 'production'
        # upload to github (canonical store)
        Store.upload(filepath, content)
        # upload to s3 (serves file)
        s3_upload(filepath, content)
      else
        rootpath = "#{File.dirname(__FILE__)}/../../../content/media/"
        FileSystem.new.upload(rootpath + filepath, content)
      end

      URI.join(ENV['MEDIA_URL'], filepath).to_s
    end

    def upload_files(files, dir)
      files.map do |file|
        save(file, dir)
      end
    end

    def s3_upload(filepath, content)
      object = bucket.objects.build(filepath)
      object.content = content
      object.acl = :public_read
      object.save
    end

    def s3
      @s3 ||= S3::Service.new(
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )
    end

    def bucket
      @bucket ||= s3.bucket(ENV['AWS_BUCKET'])
    end

  end
end
