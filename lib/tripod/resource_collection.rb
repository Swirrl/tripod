# encoding: utf-8

module Tripod

  # class that wraps a collection of resources, and allows them to be serialized
  class ResourceCollection

    include Enumerable

    attr_reader :resources

    def initialize(resources)
      @resources = resources
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

    # for n-triples we can just concatenate them
    def to_nt
      nt = ""
      resources.each do |resource|
        nt += resource.to_nt
      end
      nt
    end

    def to_json(opts={})
      get_graph.dump(:jsonld)
    end

    def to_rdf
      get_graph.dump(:rdf)
    end

    def to_ttl
      get_graph.dump(:n3)
    end

    private

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