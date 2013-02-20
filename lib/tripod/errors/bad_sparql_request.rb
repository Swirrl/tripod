# encoding: utf-8
module Tripod::Errors

  # field not present error.
  class BadSparqlRequest < StandardError

    attr_accessor :parent_bad_request

    def initialize(message=nil, parent_bad_request_error=nil)
      super(message)
      parent_bad_request = parent_bad_request_error
    end
  end

end