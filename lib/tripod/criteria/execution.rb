# This module defines behaviour for criteria
module Tripod

  # this module provides execution methods to a criteria object
  module CriteriaExecution

    extend ActiveSupport::Concern

    # Execute the query and return an array of all hydrated resources
    def resources
      resources_from_sparql(build_select_query)
    end

    # Execute the query and return the first result as a hydrated resource
    def first
      sq = Tripod::SparqlQuery.new(build_select_query)
      first_sparql = sq.as_first_query_str
      resources_from_sparql(first_sparql).first
    end

    # Return how many records the current criteria would return
    def count
      sq = Tripod::SparqlQuery.new(build_select_query)
      count_sparql = sq.as_count_query_str
      result = Tripod::SparqlClient::Query.select(count_sparql)
      result[0][".1"]["value"].to_i
    end

    # PRIVATE:

    included do

      private

      def resources_from_sparql(sparql)
        uris_and_graphs = select_uris_and_graphs(sparql)
        create_and_hydrate_resources(uris_and_graphs)
      end

      def build_select_query

        # convert the order, limit and offset to extras in the right order
        extras(order_clause)
        extras(limit_clause)
        extras(offset_clause)

        # build the query.
        select_query = "SELECT ?uri ?graph WHERE { GRAPH ?graph { "
        select_query += self.where_clauses.join(" . ")
        select_query += " } } "
        select_query += self.extra_clauses.join(" ")
        select_query.strip
      end

      # create and hydrate the resources identified in uris_and_graphs.
      # Note: if any of the graphs are not set, those resources can still be constructed, but not persisted back to DB.
      def create_and_hydrate_resources(uris_and_graphs)

        graph = self.resource_class.describe_uris(uris_and_graphs.keys) #uses the resource_class on the criteria object
        repo = self.resource_class.add_data_to_repository(graph)

        resources = []

        uris_and_graphs.each_pair do |u,g|

          # instantiate a new resource
          r = self.resource_class.new(u,g)

          # make a graph of data for this resource's uri
          data_graph = RDF::Graph.new
          repo.query( [RDF::URI.new(u), :predicate, :object] ) do |statement|
            data_graph << statement
          end

          # use it to hydrate this resource
          r.hydrate!(:graph => data_graph)
          r.new_record = false
          resources << r
        end

        resources
      end


      # based on the query passed in, build a hash of uris->graphs
      # @param [ String] sparql. The sparql query
      # @param [ Hash ] opts. A hash of options.
      #
      # @option options [ String ] uri_variable The name of the uri variable in the query, if not 'uri'
      # @option options [ String ] graph_variable The name of the uri variable in thh query, if not 'graph'
      def select_uris_and_graphs(sparql, opts={})
        select_results = Tripod::SparqlClient::Query.select(sparql)

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