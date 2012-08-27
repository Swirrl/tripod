# encoding: utf-8

# module for all domain objects that need to be persisted to the database
# as resources
module Tripod::Resource

  extend ActiveSupport::Concern

  include Tripod::Components

  included do
    # every resource needs a graph and a uri set.
    validates_presence_of :uri, :graph_uri
  end

  attr_reader :new_record
  attr_reader :graph_uri
  attr_reader :uri

  # Instantiate a +Resource+.
  # Optionsally pass a uri
  #
  # @example Instantiate a new Resource
  #   Person.new('http://swirrl.com/ric.rdf#me')
  #
  # @param [ String, RDF::URI ] uri The uri of the resource.
  #
  # @return [ Resource ] A new +Resource+
  def initialize(uri=nil, graph_uri=nil)
    @new_record = true
    @uri = RDF::URI(uri.to_s) if uri
    @graph_uri = RDF::URI(graph_uri.to_s) if graph_uri
    @repository = RDF::Repository.new
  end

  # Set the uri for this resource
  def uri=(new_uri)
    if new_uri
      @uri = RDF::URI(new_uri.to_s)
    else
      @uri = nil
    end
  end

  # Set the uri for this resource
  def graph_uri=(new_graph_uri)
    if new_graph_uri
      @graph_uri = RDF::URI(new_graph_uri.to_s)
    else
      @graph_uri = nil
    end
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