# encoding: utf-8

# This module defines behaviour for finders.
module Tripod::Finders
  extend ActiveSupport::Concern

  module ClassMethods

    # Find a +Resource+ by its uri (and, optionally, by its graph if there are more than one).
    #
    # @example Find a single resource by a uri.
    #   Person.find('http://ric')
    #   Person.find(RDF::URI('http://ric'))
    # @example Find a single resource by uri and graph
    #   Person.find('http://ric', 'http://example.com/people')
    #   Person.find(RDF::URI('http://ric'), Person.find(RDF::URI('http://example.com/people')))
    #
    # @param [ String, RDF::URI ] uri The uri of the resource to find
    # @param [ String, RDF::URI ] graph_uri The uri of the graph from which to get the resource
    #
    # @raise [ Tripod::Errors::ResourceNotFound ] If no resource found.
    #
    # @return [ Resource ] A single resource
    def find(uri, graph_uri=nil)

      unless graph_uri
        # do a quick select to see what graph to use.
        select_query = "SELECT ?g WHERE { GRAPH ?g {<#{uri.to_s}> ?p ?o } } LIMIT 1"
        result = Tripod::SparqlClient::Query.select(select_query)
        if result.length > 0
          graph_uri = result[0]["g"]["value"]
        else
          raise Tripod::Errors::ResourceNotFound.new
        end
      end

      # instantiate and hydrate the resource
      resource = self.new(uri, graph_uri.to_s)

      resource.hydrate!
      resource.new_record = false

      # check that there are triples for the resource (catches case when someone has deleted data
      # between our original check for the graph and hydrating the object.
      raise Tripod::Errors::ResourceNotFound.new if resource.repository.empty?

      # return the instantiated, hydrated resource
      resource
    end

    # Find a collection of +Resource+s by a SPARQL select statement which returns their uris.
    # Under the hood, this only executes two queries: a select, then a describe.
    #
    # @example
    #   Person.where('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } } LIMIT 3')
    #
    # @param [ String ] criteria. A sparql query which returns a list of uris of the objects.
    # @param [ Hash ] opts. A hash of options.
    #
    # @option options [ String ] uri_variable The name of the uri variable in thh query, if not 'uri'
    # @option options [ String ] graph_variable The name of the uri variable in thh query, if not 'graph'
    # @option options [ String, RDF:URI, Array] only_hydrate a single predicate or list of predicates to hydrate the returned objects with. If ommited, does a full hydrate
    #
    # @return [ Array ] An array of hydrated resources of this class's type.
    def where(criteria, opts={})
      uris_and_graphs = select_uris_and_graphs(criteria, opts)
      create_and_hydrate_resources(uris_and_graphs)
    end

    # create and hydrate the resources identified in uris_and_graphs.
    # Note: if any of the  graphs are not set, those resources can still be constructed, but not persisted back to DB.
    def create_and_hydrate_resources(uris_and_graphs)

      repository = describe_uris(uris_and_graphs.keys)

      resources = []

      uris_and_graphs.each_pair do |u,g|

        # instantiate a new resource
        r = self.new(u,g)

        # make a graph of data for this resource's uri
        data_graph = RDF::Graph.new
        repository.query( [RDF::URI.new(u), :predicate, :object] ) do |statement|
          data_graph << statement
        end

        # use it to hydrate this resource
        r.hydrate!(:graph => data_graph)
        r.new_record = false
        resources << r
      end

      resources
    end

  end

  # FOLLOWING METHODS NOT PART OF THE PUBLIC API:
  def self.included(base)

    class << base

      private

      # for an array of uris, return a RDF::Repository object with all their data.
      def describe_uris(uris)

        repo = RDF::Repository.new()

        if uris.length > 0
          uris_sparql_str = uris.map{ |u| "<#{u.to_s}>" }.join(" ")

          # Do a big describe statement, and read the results into an in-memory repo
          triples = Tripod::SparqlClient::Query::describe("DESCRIBE #{uris_sparql_str}")
          RDF::Reader.for(:ntriples).new(triples) do |reader|
            reader.each_statement do |statement|
              repo << statement
            end
          end
        end

        repo
      end

      # based on the query passed in, build a hash of uris->graphs
      def select_uris_and_graphs(criteria, opts)
        select_results = Tripod::SparqlClient::Query.select(criteria)

        uris_and_graphs = {}

        select_results.each do |r|
          uri_variable = opts[:uri_variable] || 'uri'
          graph_variable = opts[:graph_variable] || 'graph'
          uris_and_graphs[ r[uri_variable]["value"] ] = r[graph_variable]["value"]
        end

        uris_and_graphs
      end


    end

  end
end