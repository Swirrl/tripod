# This module defines behaviour for criteria
module Tripod

  # this module provides execution methods to a criteria object
  module CriteriaExecution

    extend ActiveSupport::Concern

    # Execute the query and return a +ResourceCollection+ of all hydrated resources
    # +ResourceCollection+ is an +Enumerable+, Array-like object.
    #
    # @option options [ String ] return_graph Indicates whether to return the graph as one of the variables.
    def resources(opts={})
      Tripod::ResourceCollection.new(
        self.resource_class._resources_from_sparql(self.as_query(opts)),
         # pass in the criteria that was used to generate this collection, as well as whether the user specified return graph
        :return_graph => (opts.has_key?(:return_graph) ? opts[:return_graph] : true),
        :criteria => self
      )
    end

    # run a query to get the raw serialisation of the results of this criteria object.
    #
    # @option options [ String ] return_graph Indicates whether to return the graph as one of the variables.
    # @option options [ String ] accept_header The accept header to use for serializing (defaults to application/n-triples)
    def serialize(opts={})
      select_sparql = self.as_query(:return_graph => opts[:return_graph])
      self.resource_class._raw_describe_select_results(select_sparql, :accept_header => opts[:accept_header]) # note that this method defaults to using application/n-triples.
    end

    # Execute the query and return the first result as a hydrated resource
    #
    # @option options [ String ] return_graph Indicates whether to return the graph as one of the variables.
    def first(opts={})
      sq = Tripod::SparqlQuery.new(self.as_query(opts))
      first_sparql = sq.as_first_query_str
      self.resource_class._resources_from_sparql(first_sparql).first
    end

    # Return how many records the current criteria would return
    #
    # @option options [ String ] return_graph Indicates whether to return the graph as one of the variables.
    def count(opts={})
      sq = Tripod::SparqlQuery.new(self.as_query(opts))
      count_sparql = sq.as_count_query_str
      result = Tripod::SparqlClient::Query.select(count_sparql)
      result[0]["tripod_count_var"]["value"].to_i
    end

    # turn this criteria into a query
    def as_query(opts={})
      Tripod.logger.debug("TRIPOD: building select query for criteria...")

      return_graph = opts.has_key?(:return_graph) ? opts[:return_graph] : true

      Tripod.logger.debug("TRIPOD: with return_graph: #{return_graph.inspect}")

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

      select_query += self.query_where_clauses.join(" . ")
      select_query += " } "
      select_query += "} " if return_graph || graph_uri # close the graph clause
      select_query += self.extra_clauses.join(" ")

      select_query += [order_clause, limit_clause, offset_clause].join(" ")

      select_query.strip
    end

  end
end