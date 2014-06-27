# encoding: utf-8
module Tripod::Fields
  # Defines the behaviour for defined fields in the resource.
  class Standard

    # Set readers for the instance variables.
    attr_accessor :name, :predicate, :options, :datatype, :is_uri, :multivalued
    alias_method :is_uri?, :is_uri
    alias_method :multivalued?, :multivalued

    # Create the new field with a name and optional additional options.
    #
    # @example Create the new field.
    #   Field.new(:name, 'http://foo', opts)
    #
    # @param [ String ] name The field name.
    # @param [ String, RDF::URI ] predicate The field's predicate.
    # @param [ Hash ] options The field options.
    #
    # @option options [ String, RDF::URI ] datatype The uri of the datatype for the field (will be used to create an RDF::Literal of the right type on the way in only).
    # @option options [ Boolean ] multivalued Is this a multi-valued field? Default is false.
    def initialize(name, predicate, options = {})
      @name = name
      @options = options
      @predicate = RDF::URI.new(predicate.to_s)
      @datatype = RDF::URI.new(options[:datatype].to_s) if options[:datatype]
      @is_uri = !!options[:is_uri]
      @multivalued = options[:multivalued] || false
    end
  end
end