# encoding: utf-8

# This module wraps access to an RDF::Repository
module Tripod::Repository
  extend ActiveSupport::Concern

  attr_reader :repository

  # hydrates the resource's repo with statements from the db or passed in graph of statements.
  # where the subject is the uri of this resource.
  #
  # @example Hydrate the resource from the db
  #   person.hydrate!
  #
  # @example Hydrate the resource from a passed in graph
  #   person.hydrate!(:graph => my_graph)
  #
  # @example Only hydrate certain predicates (ignored if a graph is passde in)
  #   person.hydrate!(:only => ["http://foo", "http://bar"])
  #   person.hydrate!(:only => "http://foo")
  #
  #
  # @return [ RDF::Repository ] A reference to the repository for this instance.
  def hydrate!(opts = {})

    graph = opts[:graph]
    only_hydrate_predicates = [opts[:only]].flatten # allow

    # we require that the uri is set.
    raise Tripod::Errors::UriNotSet.new() unless @uri

    @repository = RDF::Repository.new # make sure that the repo is empty before we begin

    if graph
      graph.each_statement do |statement|
        # only use statements about this resource!
        if statement.subject.to_s == @uri.to_s
          @repository << statement
        end
      end
    else

      unless only_hydrate_predicates && only_hydrate_predicates.any?
        triples = Tripod::SparqlClient::Query::describe("DESCRIBE <#{uri}>")
      else
        query = "CONSTRUCT { <#{uri}> ?p ?o } WHERE { <#{uri}> ?p ?o . FILTER ("
        query += only_hydrate_predicates.map { |p| "?p = <#{p.to_s}>" }.join(" || ")
        query += ")}"
        triples = Tripod::SparqlClient::Query::construct(query)
      end

      @repository = RDF::Repository.new
      RDF::Reader.for(:ntriples).new(triples) do |reader|
        reader.each_statement do |statement|
          @repository << statement
        end
      end
    end

  end

end