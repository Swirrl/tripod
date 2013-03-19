# encoding: utf-8
module Tripod::Errors

  # not found error.
  class ResourceNotFound < StandardError

    attr_accessor :uri

    def initialize(uri=nil)
      @uri = uri
    end

    def message
      msg = "Resource Not Found"
      msg += ": #{@uri.to_s}" if @uri
      msg
    end
  end

end