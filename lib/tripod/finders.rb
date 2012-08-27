# encoding: utf-8

# This module defines behaviour for finders.
module Tripod::Finders
  extend ActiveSupport::Concern

  module ClassMethods

    # Find a +Resource+ by its uri.
    #
    # @example Find a single resource by a uri.
    #   Person.find('http://ric')
    #   Person.find(RDF::URI('http://ric'))
    #
    # @param [ String, RDF::URI ] uri The uri of the resource to find
    #
    # @raise [ Tripod::Errors::ResourceNotFound ] If no resource found.
    #
    # @return [ Resource ] A single resource
    def find(uri)

      # do a quick select to see what graph to use.
      select_query = "SELECT ?g WHERE { GRAPH ?g {<#{uri.to_s}> ?p ?o } } LIMIT 1"
      result = Tripod::SparqlClient::Query.select(select_query)
      if result.length > 0
        graph_uri_str = result[0]["g"]["value"]
      else
        raise Tripod::Errors::ResourceNotFound.new
      end

      # instantiate and hydrate the resource
      resource = self.new(uri, graph_uri_str)
      resource.hydrate!

      # check that there are triples for the resource (catches case when someone has deleted data
      # between our original check for the graph and hydrating the object.
      raise Tripod::Errors::ResourceNotFound.new if resource.repository.empty?

      # return the instantiated, hydrated resource
      resource
    end

  end
end