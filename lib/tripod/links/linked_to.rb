# encoding: utf-8
module Tripod::Links
  # Defines the behaviour for defined links in the resource.
  class LinkedTo

    # Set readers for the instance variables.
    attr_accessor :name, :predicate, :options, :multivalued, :field_name, :class_name
    alias_method :multivalued?, :multivalued

    # Create the new link with a name and optional additional options.
    def initialize(name, predicate, options = {})
      @name = name
      @options = options
      @predicate = RDF::URI.new(predicate.to_s)
      @multivalued = options[:multivalued] || false
      @class_name = options[:class_name] || @name.to_s.classify
      @field_name = options[:field_name] || (@name.to_s + ( @multivalued ? "_uris" : "_uri" )).to_sym

    end
  end
end