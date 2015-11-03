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
        # Note that we use all statements, even those not about this resource, in case we're being
        # passed eager-loaded ones.
        @repository << statement
      end
    else

      triples = retrieve_triples_from_database

      @repository = RDF::Repository.new
      RDF::Reader.for(:ntriples).new(triples) do |reader|
        reader.each_statement do |statement|
          @repository << statement
        end
      end
    end

  end

  # returns a graph of all triples in the repository
  def repository_as_graph
    g = RDF::Graph.new
    @repository.each_statement do |s|
      g << s
    end
    g
  end

  def retrieve_triples_from_database(accept_header="application/n-triples, text/plain")
    Tripod::SparqlClient::Query.query(self.class.all_triples_query(uri, graph_uri: self.graph_uri), accept_header)
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

    def append_to_hydrate_construct(statement)
      @construct_statements ||= []
      @construct_statements << statement
    end

    def append_to_hydrate_where(statement)
      @where_statements ||= []
      @where_statements << statement
    end

    def all_triples_query(uri, opts={})
      graph_uri = opts.fetch(:graph_uri, nil)
      graph_selector = graph_uri.present? ? "<#{graph_uri.to_s}>" : "?g"
      uri_selector = "<#{uri}>"
      "CONSTRUCT { #{uri_selector} ?p ?o . #{ all_triples_construct(uri_selector) } } WHERE { GRAPH #{graph_selector} { #{uri_selector} ?p ?o . #{ all_triples_where(uri_selector) } } }"
    end

    def all_triples_construct(uri)
      extra_construct = @construct_statements.map{|s| s.call(uri) }.join if @construct_statements.present?
      extra_construct || ''
    end

    def all_triples_where(uri)
      extra_where = @where_statements.map{|s| s.call(uri) }.join if @where_statements.present?
      extra_where || ''
    end

  end

end
