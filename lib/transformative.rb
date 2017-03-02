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

%w( utils post card cite entry event auth context media micropub notification
    syndication authorship notification webmention view_helper cache twitter
    file_system store inflections server ).each do |file|
  require_relative "transformative/#{file}.rb"
end
