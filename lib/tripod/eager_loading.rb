module Tripod::EagerLoading

  extend ActiveSupport::Concern

  # array of resources that represent the predicates of the triples of this resource
  attr_reader :predicate_resources

  # array of resources that represent the objects of the triples of this resource
  attr_reader :object_resources

  # get all the triples in the db where the predicate uri is their subject
  # stick the results in this resource's repo
  def eager_load_predicate_triples!
    graph_of_triples = self.class.describe_uris(predicates)
    self.class.add_data_to_repository(graph_of_triples, self.repository)
  end

  # get all the triples in the db where the object uri is their subject
  # stick the results in this resource's repo
  def eager_load_object_triples!
    object_uris = []

    self.repository.query( [RDF::URI.new(self.uri), :predicate, :object] ) do |statement|
      object_uris << statement.object if statement.object.uri?
    end

    object_uris = object_uris.uniq # in case an object appears > once.
    graph_of_triples = self.class.describe_uris(object_uris)
    self.class.add_data_to_repository(graph_of_triples, self.repository)
  end

  # get the resource that represents a particular uri. If there's triples in our repo where that uri
  # is the subject, use that to hydrate a resource, otherwise justdo a find against the db.
  def get_related_resource(resource_uri, class_of_resource_to_create)
    data_graph = RDF::Graph.new

    self.repository.query( [ RDF::URI.new(resource_uri.to_s), :predicate, :object] ) do |stmt|
      data_graph << stmt
    end

    if data_graph.empty?
      # this means that we've not already looked it up
      r = class_of_resource_to_create.find(resource_uri)
    else
      # it's in our eager loaded repo
      r = class_of_resource_to_create.new(resource_uri)
      r.hydrate!(:graph => data_graph)
      r.new_record = false
      r
    end
    r
  end

end