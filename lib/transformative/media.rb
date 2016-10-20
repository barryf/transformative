# TODO: upload file to s3

module Transformative
  module Media
    module_function

    def store(file)
      filename = "#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex.to_s}"
      ext = file[:filename].match(/\./) ? '.' +
        file[:filename].split('.').last : ""

      File.write("#{ENV['MEDIA_PATH']}#{filename}#{ext}", file[:tempfile].read)

      URI.join(ENV['MEDIA_URL'], "#{filename}#{ext}")
    end

    def upload_files(files)
      files.map do |file|
        store(file)
      end
    end

  end
end
