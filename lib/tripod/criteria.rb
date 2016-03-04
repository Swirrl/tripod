# encoding: utf-8
require "tripod/criteria/execution"

module Tripod

  # This module defines behaviour for criteria
  class Criteria

   include Tripod::CriteriaExecution

    # the resource class that this criteria is for.
    attr_accessor :resource_class

    attr_accessor :where_clauses
    attr_accessor :extra_clauses

    attr_accessor :limit_clause
    attr_accessor :order_clause
    attr_accessor :offset_clause
    attr_accessor :graph_uri
    attr_accessor :graph_lambdas

    def initialize(resource_class)
      self.resource_class = resource_class
      self.where_clauses = []
      self.extra_clauses = []
      self.graph_lambdas = []

      if resource_class._RDF_TYPE
        self.where("?uri a <#{resource_class._RDF_TYPE.to_s}>")
      end

      self.graph_uri = resource_class._GRAPH_URI.to_s if resource_class._GRAPH_URI
    end

    # they're equal if they return the same query
    def ==(other)
      as_query == other.send(:as_query)
    end

    # Takes a string and adds a where clause to this criteria.
    # Returns a criteria object.
    # Note: the subject being returned by the query must be identified by ?uri
    # e.g. my_criteria.where("?uri a <http://my-type>")
    #
    def where(filter)
      if filter.is_a?(String) # we got a Sparql snippet
        where_clauses << filter
      elsif filter.is_a?(Hash)
        filter.each_pair do |key, value|
          field = resource_class.get_field(key)
          value = RDF::Literal.new(value) unless value.respond_to?(:to_base)
          where_clauses << "?uri <#{ field.predicate }> #{ value.to_base }"
        end
      end
      self
    end

    def query_where_clauses
      where_clauses.empty? ? ['?uri ?p ?o'] : where_clauses
    end
    # takes a string and adds an extra clause to this criteria.
    # e.g. my_criteria.extras("LIMIT 10 OFFSET 20").extrass
    #
    # TODO: make it also take a hash?
    def extras(sparql_snippet)
      extra_clauses << sparql_snippet
      self
    end

    # replaces this criteria's limit clause
    def limit(the_limit)
      self.limit_clause = "LIMIT #{the_limit.to_s}"
      self
    end

    # replaces this criteria's offset clause
    def offset(the_offset)
      self.offset_clause = "OFFSET #{the_offset.to_s}"
      self
    end

    # replaces this criteria's order clause
    def order(param)
      self.order_clause = "ORDER BY #{param}"
      self
    end

    # Restrict this query to the graph uri passed in
    # You may also pass a block to an unbound graph, ?g
    # then chain a where clause to the criteria returned to bind ?g
    #
    # @example .graph(RDF::URI.new('http://graphoid')
    # @example .graph('http://graphoid')
    # @example .graph(nil) { "?s ?p ?o" }.where("?uri ?p ?g")
    #
    # @param [ String, RDF::URI ] The graph uri
    # @param [ Block ] A string to be executed within an unbound graph, ?g
    #
    # @return [ Tripod::Criteria ] A criteria object
    def graph(graph_uri, &block)

      if block_given?
        self.graph_lambdas ||= []
        self.graph_lambdas << block
        self
      else
        self.graph_uri = graph_uri.to_s
        self
      end
    end
  end
end
