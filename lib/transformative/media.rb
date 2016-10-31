module Transformative
  module Media
    module_function

    def save(file)
      filename = "#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex.to_s}"
      ext = file.key?('filename') && file[:filename].match(/\./) ? '.' +
        file[:filename].split('.').last : ".jpg"
      filepath = "file/#{filename}#{ext}"
      content = file[:tempfile].read

      if ENV['RACK_ENV'] == 'production'
        # upload to github (canonical store)
        Store.upload(filepath, content)
        # upload to s3 (serves file)
        s3_upload(filepath, content, ext, file[:type])
      else
        rootpath = "#{File.dirname(__FILE__)}/../../../content/media/"
        FileSystem.new.upload(rootpath + filepath, content)
      end

      URI.join(ENV['MEDIA_URL'], filepath).to_s
    end

    def upload_files(files)
      files.map do |file|
        if Utils.valid_url?(file)
          # TODO extract file from url and store?
          file
        else
          save(file)
        end
      end
    end

    def s3_upload(filepath, content, ext, content_type)
      object = bucket.objects.build(filepath)
      object.content = content
      object.content_type = content_type
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
