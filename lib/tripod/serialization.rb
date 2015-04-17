# encoding: utf-8

require 'tripod/http/content_type'

module Tripod::Serialization
  extend ActiveSupport::Concern

  # Serialises this resource's triples to rdf/xml
  def to_rdf
    retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.RDFXml)
  end

  # Serialises this resource's triples to turtle
  def to_ttl
    retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.Turtle)
  end

  # Serialises this resource's triples to n-triples
  def to_nt
    retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.NTriples)
  end

  # Serialises this resource's triples to JSON-LD
  def to_json(opts={})
    get_triples_for_this_resource.dump(:jsonld)
  end

  def to_text
    to_nt
  end

end