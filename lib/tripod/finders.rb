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

    # execute a where clause on this resource.
    # returns a criteria object
    def where(sparql_snippet)
      criteria = Tripod::Criteria.new(self)
      criteria.where(sparql_snippet)
    end

    # execute a query to return all objects (restricted by this class's rdf_type if specified)
    # returns a criteria object
    def all
      criteria = Tripod::Criteria.new(self)
      criteria
    end

    def count
      self.all.count
    end

    def first
      self.all.first
    end

    # returns a graph of triples which describe the uris passed in.
    def describe_uris(uris)
      graph = RDF::Graph.new

      if uris.length > 0
        uris_sparql_str = uris.map{ |u| "<#{u.to_s}>" }.join(" ")

        # Do a big describe statement, and read the results into an in-memory repo
        triples_string = Tripod::SparqlClient::Query.describe("DESCRIBE #{uris_sparql_str}")

        RDF::Reader.for(:ntriples).new(triples_string) do |reader|
          reader.each_statement do |statement|
            graph << statement
          end
        end

      end

      graph
    end

  end
end