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
    #
    # @return [ Array ] An array of hydrated resources of this class's type.
    def where(criteria, opts={})

      # 1. Run the select.
      select_results = Tripod::SparqlClient::Query.select(criteria)

      # data will contain a map of uris against graphs.
      data = {}

      select_results.each do |r|
        uri_variable = opts[:uri_variable] || 'uri'
        graph_variable = opts[:graph_variable] || 'graph'
        data[ r[uri_variable]["value"] ] = r[graph_variable]["value"]
      end

      resources = []

      if data.keys.length > 0

        uris_sparql_str = data.keys.map{ |u| "<#{u}>" }.join(" ")

        # 2. Do a big describe statement, and read the results into an in-memory repo
        triples = Tripod::SparqlClient::Query::describe("DESCRIBE #{uris_sparql_str}")
        triples_repository = RDF::Repository.new()
        RDF::Reader.for(:ntriples).new(triples) do |reader|
          reader.each_statement do |statement|
            triples_repository << statement
          end
        end

        # 3. for each of our uris, make a resource, with a graph of triples for that uri from the in-mem repo
        data.each_pair do |u,g|
          r = self.new(u,g)
          data_graph = RDF::Graph.new
          triples_repository.query( [RDF::URI.new(u), :predicate, :object] ) do |statement|
            data_graph << statement
          end
          r.hydrate!(:graph => data_graph)
          r.new_record = false
          resources << r
        end
      end
      resources

    end
  end
end