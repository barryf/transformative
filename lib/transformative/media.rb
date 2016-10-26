# TODO: upload file to s3

module Transformative
  module Media
    module_function

    def store(file, dir)
      filename = "#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex.to_s}"
      ext = file[:filename].match(/\./) ? '.' +
        file[:filename].split('.').last : ""

      File.write("#{ENV['MEDIA_PATH']}#{dir}/#{filename}#{ext}", file[:tempfile].read)

      URI.join(ENV['MEDIA_URL'], "#{dir}/", "#{filename}#{ext}")
    end

    def upload_files(files, dir)
      files.map do |file|
        store(file, dir)
      end
    end

  end
end
