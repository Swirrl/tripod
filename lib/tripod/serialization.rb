# encoding: utf-8

# This module defines behaviour for finders.
module Tripod::Serialization
  extend ActiveSupport::Concern

  # Serialises this resource's triples to rdf/xml
  def to_rdf
    get_triples_for_this_resource.dump(:rdfxml)
  end

  # Serialises this resource's triples to turtle
  def to_ttl
    get_triples_for_this_resource.dump(:n3)
  end

  # Serialises this resource's triples to n-triples
  def to_nt
    get_triples_for_this_resource.dump(:ntriples)
  end

  # Serialises this resource's triples to JSON-LD
  def to_json(opts={})
    get_triples_for_this_resource.dump(:jsonld)
  end

end