# encoding: utf-8
module Tripod::Links
  # Defines the behaviour for defined links in the resource.
  class LinkedFrom

    # Set readers for the instance variables.
    attr_accessor :name, :incoming_field, :options, :incoming_field_name, :class_name

    # Create the new link with a name and optional additional options.
    def initialize(name, incoming_field_name, options = {})
      @name = name
      @options = options
      @incoming_field_name = incoming_field_name
      # if class name not supplied, guess from the field name
      @class_name = options[:class_name] || name.to_s.singularize.classify

    end
  end
end