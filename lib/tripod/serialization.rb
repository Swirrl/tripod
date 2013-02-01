# encoding: utf-8

# This module defines behaviour for finders.
module Tripod::Serialization
  extend ActiveSupport::Concern

  def to_rdf
    @repository.dump(:rdfxml)
  end

  def to_ttl
    @repository.dump(:n3)
  end

  def to_nt
    @repository.dump(:ntriples)
  end

  # how to do json?.

end