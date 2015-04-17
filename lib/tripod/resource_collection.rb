# encoding: utf-8

require 'tripod/http/content_type'

module Tripod

  # class that wraps a collection of resources, and allows them to be serialized
  class ResourceCollection

    include Enumerable

    attr_reader :resources
    attr_reader :criteria # the criteria used to generate this collection
    attr_reader :sparql_query_str # the sparql query used to generate this collection

    # options:
    #  :criteria - the criteria used to create this collection
    #  :sparql_query_str - the sparql used to create this collection
    #  :return_graph - whether the original query returned the graphs or not.
    def initialize(resources, opts={})
      @resources = resources
      @criteria = opts[:criteria]
      @sparql_query_str = opts[:sparql_query_str]
      @resource_class = opts[:resource_class]
      @return_graph = opts[:return_graph]
    end

    def length
      self.resources.length
    end

    def each
      self.resources.each { |e| yield(e) }
    end

    # return the underlying array
    def to_a
      resources
    end

    # allow index operator to act on underlying array of resources.
    def [](*args)
      resources[*args]
    end

    def ==(other)
      self.to_nt == other.to_nt
    end

    def to_text
      to_nt
    end

    # for n-triples we can just concatenate them
    def to_nt
      time_serialization('nt') do
        if @criteria
          @criteria.serialize(:return_graph => @return_graph, :accept_header => Tripod::Http::ContentType.NTriples)
        elsif @sparql_query_str && @resource_class
          # run the query as a describe.
          @resource_class._raw_describe_select_results(@sparql_query_str, :accept_header => Tripod::Http::ContentType.NTriples)
        else
          # for n-triples we can just concatenate them
          nt = ""
          resources.each do |resource|
            nt += resource.to_nt
          end
          nt
        end
      end
    end

    def to_json(opts={})
      # most databases don't have a native json-ld implementation.
      time_serialization('json') do
        get_graph.dump(:jsonld)
      end
    end

    def to_rdf
      time_serialization('rdf') do
        if @criteria
          @criteria.serialize(:return_graph => @return_graph, :accept_header => Tripod::Http::ContentType.RDFXml)
        elsif @sparql_query_str && @resource_class
          # run the query as a describe.
          @resource_class._raw_describe_select_results(@sparql_query_str, :accept_header => Tripod::Http::ContentType.RDFXml)
        else
          get_graph.dump(:rdf)
        end
      end
    end

    def to_ttl
      time_serialization('ttl') do
        if @criteria
          @criteria.serialize(:return_graph => @return_graph, :accept_header => Tripod::Http::ContentType.Turtle)
        elsif @sparql_query_str && @resource_class
          # run the query as a describe.
          @resource_class._raw_describe_select_results(@sparql_query_str, :accept_header => Tripod::Http::ContentType.Turtle)
        else
          get_graph.dump(:turtle)
        end
      end
    end

    private

    def time_serialization(format)
      start_serializing = Time.now if Tripod.logger.debug?
      result = yield if block_given?
      serializing_duration = Time.now - start_serializing if Tripod.logger.debug?
      Tripod.logger.debug( "TRIPOD: Serializing collection to #{format} took #{serializing_duration} secs" )
      result
    end

    def get_graph
      graph = RDF::Graph.new
      RDF::Reader.for(:ntriples).new(self.to_nt) do |reader|
        reader.each_statement do |statement|
          graph << statement
        end
      end
    end

  end

end