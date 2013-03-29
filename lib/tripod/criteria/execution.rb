# This module defines behaviour for criteria
module Tripod

  # this module provides execution methods to a criteria object
  module CriteriaExecution

    extend ActiveSupport::Concern

    # Execute the query and return a +ResourceCollection+ of all hydrated resources
    # +ResourceCollection+ is an +Enumerable+, Array-like object.
    # options:
      #  :return_graph (default true) # indicates whether to return the graph as one of the variables.
    def resources(opts={})
      Tripod::ResourceCollection.new(
        self.resource_class._resources_from_sparql(build_select_query(opts))
      )
    end

    # Execute the query and return the first result as a hydrated resource
    # options:
    #  :return_graph (default true) # indicates whether to return the graph as one of the variables.
    def first(opts={})
      sq = Tripod::SparqlQuery.new(build_select_query(opts))
      first_sparql = sq.as_first_query_str
      self.resource_class._resources_from_sparql(first_sparql).first
    end

    # Return how many records the current criteria would return
    # options:
    #  :return_graph (default true) # indicates whether to return the graph as one of the variables.
    def count(opts={})
      sq = Tripod::SparqlQuery.new(build_select_query(opts))
      count_sparql = sq.as_count_query_str
      result = Tripod::SparqlClient::Query.select(count_sparql)
      result[0]["c"]["value"].to_i
    end

    # PRIVATE:

    included do

      private

      # options:
      #  :return_graph (default true) # indicates whether to return the graph as one of the variables.
      def build_select_query(opts={})

        return_graph = opts.has_key?(:return_graph) ? opts[:return_graph] : true

        select_query = "SELECT DISTINCT ?uri "

        if return_graph
          # if we are returing the graph, select it as a variable, and include either the <graph> or ?graph in the where clause
          if graph_uri
            select_query += "(<#{graph_uri}> as ?graph) WHERE { GRAPH <#{graph_uri}> { "
          else
            select_query += "?graph WHERE { GRAPH ?graph { "
          end
        else
          select_query += "WHERE { "
          # if we're not returning the graph, only restrict by the <graph> if there's one set at class level
          select_query += "GRAPH <#{graph_uri}> { " if graph_uri
        end

        select_query += self.where_clauses.join(" . ")
        select_query += " } "
        select_query += "} " if return_graph || graph_uri # close the graph clause
        select_query += self.extra_clauses.join(" ")

        select_query += [order_clause, limit_clause, offset_clause].join(" ")

        select_query.strip
      end

    end

  end
end