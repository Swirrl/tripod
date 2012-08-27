# encoding: utf-8
module Tripod::Errors

  # Raised when a persistence method ending in ! fails validation. The message
  # will contain the full error messages from the +Resource+ in question.
  #
  # @example Create the error.
  #   Validations.new(person.errors)
  class Validations < StandardError
    attr_reader :resource
    alias :record :resource

    def initialize(resource)
      @resource = resource
    end
  end

end
