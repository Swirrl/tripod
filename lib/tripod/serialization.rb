# encoding: utf-8

# This module defines behaviour for finders.
module Tripod::Serialization
  extend ActiveSupport::Concern

  # Serialises this resource's triples to rdf/xml
  def to_rdf
    @repository.dump(:rdfxml)
  end

  # Serialises this resource's triples to turtle
  def to_ttl
    @repository.dump(:n3)
  end

  # Serialises this resource's triples to n-triples
  def to_nt
    @repository.dump(:ntriples)
  end

  # Serialises this resource's triples to JSON-LD
  def to_json(opts={})
    @repository.dump(:jsonld)
  end

end