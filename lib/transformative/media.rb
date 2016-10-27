module Transformative
  module Media
    module_function

    def save(file, dir='photo')
      filename = "#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex.to_s}"
      ext = file[:filename].match(/\./) ? '.' +
        file[:filename].split('.').last : ""
      filepath = "#{dir}/#{filename}#{ext}"

      if ENV['RACK_ENV'] == 'production'
        Store.upload(filepath, file[:tempfile].read)
      else
        FileSystem.new.upload(filepath, file[:tempfile].read)
      end

      URI.join(ENV['MEDIA_URL'], "#{dir}/", "#{filename}#{ext}")
    end

    def upload_files(files, dir)
      files.map do |file|
        save(file, dir)
      end
    end

  end
end
