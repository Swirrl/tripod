# encoding: utf-8

# module for all domain objects that need to be persisted to the database
# as resources
module Tripod::Resource

  extend ActiveSupport::Concern

  include Tripod::Components

  attr_reader :new_record
  attr_accessor :uri

  # Instantiate a +Resource+.
  # Optionsally pass a uri
  #
  # @example Instantiate a new Resource
  #   Person.new('http://swirrl.com/ric.rdf#me')
  #
  # @param [ String, RDF::URI ] uri The uri of the resource.
  #
  # @return [ Resource ] A new +Resource+
  def initialize(uri=nil)
    @new_record = true
    @uri = RDF::URI(uri.to_s) if uri
    @repository = RDF::Repository.new
  end

  # default comparison is via the uri
  def <=>(other)
    uri.to_s <=> uri.to_s
  end

  # performs equality checking on the uris
  def ==(other)
    self.class == other.class &&
      uri.to_s == uri.to_s
  end

  # performs equality checking on the class
  def ===(other)
    other.class == Class ? self.class === other : self == other
  end

  # delegates to ==
  def eql?()
    self == (other)
  end

  def hash
    identity.hash
  end

  # a resource is absolutely identified by it's class and id.
  def identity
    [ self.class, self.uri.to_s ]
  end

  # Return the key value for the resource.
  #
  # @example Return the key.
  #   resource.to_key
  #
  # @return [ Object ] The uri of the resource or nil if new.
  def to_key
    (persisted? || destroyed?) ? [ uri.to_s ] : nil
  end

  def to_a
    [ self ]
  end

  module ClassMethods

    # Performs class equality checking.
    def ===(other)
      other.class == Class ? self <= other : other.is_a?(self)
    end

  end

end

# causes any hooks to be fired, if they've been setup on_load of :tripod.
ActiveSupport.run_load_hooks(:triploid, Tripod::Resource)