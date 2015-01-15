module Tripod::Embeds
  class Many
    include Enumerable

    def initialize(klass, predicate, parent)
      @parent = parent
      @predicate = predicate
      nodes = @parent.read_predicate(@predicate) # gets the UUIDs of the associated blank nodes
      @resources = nodes.map do |node|
        repository = RDF::Repository.new
        @parent.repository.query([node, :predicate, :object]) {|statement| repository << statement}
        klass.new(node: node, repository: repository)
      end
    end

    def each(&block)
      @resources.each(&block)
    end

    def <<(resource)
      @parent.repository.insert(*resource.to_statements)
      @parent.append_to_predicate(@predicate, resource.uri)
    end

    def delete(resource)
      statements = @parent.repository.query([resource.uri, :predicate, :object]).to_a
      statements << [@parent.uri, RDF::URI.new(@predicate), resource.uri]
      @parent.repository.delete(*statements)
    end
  end
end
