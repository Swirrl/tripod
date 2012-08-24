# encoding: utf-8

# This module wraps access to an RDF::Repository
module Tripod::Repository
  extend ActiveSupport::Concern

  attr_reader :repository

  # hydrates the resource's repo with statements from the db,
  # where the subject is the uri of this resource.
  #
  # @example Hydrage the resource
  #   person.hydrate!
  def hydrate!(graph = nil)
    if graph
      graph.each_statement do |statement|
        @repository << statement
      end
    elsif @uri # don't do anything if no uri set on the obj
      triples = Tripod::SparqlClient::Query::describe("DESCRIBE <#{uri}>")
      @repository = RDF::Repository.new
      RDF::Reader.for(:ntriples).new(triples) do |reader|
        reader.each_statement do |statement|
          @repository << statement
        end
      end

    end
  end

end