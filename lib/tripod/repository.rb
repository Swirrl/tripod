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
  #
  # @return [ RDF::Repository ] A reference to the repository for this instance.
  def hydrate!(opts = {})

    graph = opts[:graph]

    # we require that the uri is set.
    raise Tripod::Errors::UriNotSet.new() unless @uri

    @repository = RDF::Repository.new # make sure that the repo is empty before we begin

    if graph
      graph.each_statement do |statement|
        # only use statements about this resource for hydrating
        if statement.subject.to_s == @uri.to_s
          @repository << statement
        end
      end
    else
      triples = Tripod::SparqlClient::Query.query("DESCRIBE <#{uri}>", "application/n-triples")
      @repository = RDF::Repository.new
      RDF::Reader.for(:ntriples).new(triples) do |reader|
        reader.each_statement do |statement|
          @repository << statement
        end
      end
    end

  end

  # returns a graph of triples from the underlying repository where this resource's uri is the subject.
  def get_triples_for_this_resource
    triples_graph = RDF::Graph.new
    @repository.query([RDF::URI.new(self.uri), :predicate, :object]) do |stmt|
      triples_graph << stmt
    end
    triples_graph
  end

  module ClassMethods

    # for triples in the graph passed in, add them to the passed in repository obj, and return the repository objects
    # if no repository passed, make a new one.
    def add_data_to_repository(graph, repo=nil)

      repo ||= RDF::Repository.new()

      graph.each_statement do |statement|
        repo << statement
      end

      repo
    end

  end

end