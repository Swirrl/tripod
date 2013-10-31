# encoding: utf-8

# module for all domain objects that need to be persisted to the database
# as resources
module Tripod::Resource

  extend ActiveSupport::Concern

  include Tripod::Components

  included do
    # every resource needs a graph set.
    validates_presence_of :graph_uri
    # uri is a valid linked data url
    validates :uri, is_url: true
    # every instance of a resource has an rdf type field, which is set at the class level
    class_attribute :_RDF_TYPE
    # the Graph URI is set at the class level by default also, although this can be overridden in the constructor
    class_attribute :_GRAPH_URI
  end

  attr_reader :new_record
  attr_reader :graph_uri
  attr_reader :uri

  # Instantiate a +Resource+.
  #
  # @example Instantiate a new Resource
  #   Person.new('http://swirrl.com/ric.rdf#me')
  #
  # @param [ String, RDF::URI ] uri The uri of the resource.
  # @param [ String, RDF::URI ] graph_uri The graph_uri where this resource will be saved to. If ommitted, this resource cannot be persisted.
  #
  # @return [ Resource ] A new +Resource+
  def initialize(uri, graph_uri=nil)
    raise Tripod::Errors::UriNotSet.new('uri missing') unless uri
    @uri = RDF::URI(uri.to_s)
    @repository = RDF::Repository.new
    @new_record = true

    run_callbacks :initialize do
      graph_uri ||= self.class.get_graph_uri
      @graph_uri = RDF::URI(graph_uri) if graph_uri
      self.rdf_type = self.class.get_rdf_type if respond_to?(:rdf_type=) && self.class.get_rdf_type
    end
  end

  # default comparison is via the uri
  def <=>(other)
    uri.to_s <=> uri.to_s
  end

  # performs equality checking on the uris
  def ==(other)
    self.class == other.class &&
      uri.to_s == other.uri.to_s
  end

  # performs equality checking on the class
  def ===(other)
    other.class == Class ? self.class === other : self == other
  end

  # delegates to ==
  def eql?(other)
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

    # makes a "field" on this model called rdf_type
    # and sets a class level _RDF_TYPE variable with the rdf_type passed in.
    def rdf_type(new_rdf_type)
      self._RDF_TYPE = RDF::URI.new(new_rdf_type.to_s)
      field :rdf_type, RDF.type, :multivalued => true, :is_uri => true # things can have more than 1 type and often do
    end

    def get_rdf_type
      self._RDF_TYPE
    end

    def graph_uri(new_graph_uri)
      self._GRAPH_URI = new_graph_uri
    end

    def get_graph_uri
      self._GRAPH_URI
    end
  end

end

# causes any hooks to be fired, if they've been setup on_load of :tripod.
ActiveSupport.run_load_hooks(:triploid, Tripod::Resource)