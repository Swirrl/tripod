module Tripod::EmbeddedResource
  extend ActiveSupport::Concern

  include ActiveModel::Validations

  include Tripod::Predicates
  include Tripod::Attributes
  include Tripod::Validations
  include Tripod::Fields
  include Tripod::Dirty
  include Tripod::RdfType

  attr_reader :uri

  def initialize(opts={})
    @uri = opts.fetch(:node, RDF::Node.new) # use a blank node for the URI
    @repository = opts.fetch(:repository, RDF::Repository.new)
    set_rdf_type
  end

  def to_statements
    @repository.statements
  end

  def ==(resource)
    (@uri == resource.uri)
  end
end
