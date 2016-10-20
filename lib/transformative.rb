module Transformative

  class TransformativeError < StandardError
    attr_reader :type, :status
    def initialize(type, message, status=500)
      @type = type
      @status = status.to_i
      super(message)
    end
  end

end

%w( utils post auth context media micropub notification store syndication
    authorship notification webmention server ).each do |file|
  require_relative "transformative/#{file}.rb"
end
