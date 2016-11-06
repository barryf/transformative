module Transformative
  module Notification
    module_function

    def send(title, message, url)
      if ENV.key?('PUSHOVER_USER') && ENV.key?('PUSHOVER_TOKEN')
        pushover(title, message, url)
      end
    end

    def pushover(title, message, url)
      response = HTTParty.post('https://api.pushover.net/1/messages.json', {
        body: {
          token: ENV['PUSHOVER_TOKEN'],
          user: ENV['PUSHOVER_USER'],
          title: title,
          message: message,
          url: url
        }
      })
    end

  end
end
