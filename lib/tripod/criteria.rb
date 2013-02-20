# encoding: utf-8
require "tripod/criteria/execution"

module Tripod

  # This module defines behaviour for criteria
  class Criteria

   include Tripod::CriteriaExecution

    # the resource class that this criteria is for.
    attr_accessor :resource_class

    # array of all the where clauses in this criteria
    attr_accessor :where_clauses

    # array of all the extra clauses in this criteria
    attr_accessor :extra_clauses

    def initialize(resource_class)
      self.resource_class = resource_class
      self.where_clauses = []
      self.extra_clauses = []

      if resource_class._RDF_TYPE
        self.where("?uri a <#{resource_class._RDF_TYPE.to_s}>")
      else
        self.where("?uri ?p ?o")
      end
    end

    # they're equal if they return the same query
    def ==(other)
      build_select_query == other.send(:build_select_query)
    end

    # Takes a string and adds a where clause to this criteria.
    # Returns a criteria object.
    # Note: the subject being returned by the query must be identified by ?uri
    # e.g. my_criteria.where("?uri a <http://my-type>")
    #
    # TODO: make it also take a hash?
    def where(sparql_snippet)
      where_clauses << sparql_snippet
      self
    end

    # takes a string and adds an extra clause to this criteria.
    # TODO: make it also take a hash?
    def extras(sparql_snippet)
      extra_clauses << sparql_snippet
      self
    end

  end
end
