module Tripod::EagerLoading

  extend ActiveSupport::Concern

  # array of resources that represent the predicates of the triples of this resource
  attr_reader :predicate_resources

  # array of resources that represent the objects of the triples of this resource
  attr_reader :object_resources

  # get all the triples in the db where the predicate uri is their subject
  # stick the results in this resource's repo
  # options: labels_only (default false)
  # options: predicates (default nil) array of predicaets (as URIs or strings representing URIs) for fieldnames to fetch
  def eager_load_predicate_triples!(opts={})

    if opts[:labels_only]
      construct_query = "CONSTRUCT { ?p <#{RDF::RDFS.label}> ?pred_label } WHERE { <#{self.uri.to_s}> ?p ?o . ?p <#{RDF::RDFS.label}> ?pred_label }"
    elsif (opts[:predicates] && opts[:predicates].length > 0)
      construct_query = build_multifield_query(opts[:predicates],"?p")
    else
      construct_query = "CONSTRUCT { ?p ?pred_pred ?pred_label } WHERE { <#{self.uri.to_s}> ?p ?o . ?p ?pred_pred ?pred_label }"
    end

    extra_triples = self.class._graph_of_triples_from_construct_or_describe construct_query
    self.class.add_data_to_repository(extra_triples, self.repository)
  end

  # get all the triples in the db where the object uri is their subject
  # stick the results in this resource's repo
  # options: labels_only (default false)
  # options: predicates (default nil) array of predicaets (as URIs or strings representing URIs) for fieldnames to fetch
  def eager_load_object_triples!(opts={})
    object_uris = []

    if opts[:labels_only]
      construct_query = "CONSTRUCT { ?o <#{RDF::RDFS.label}> ?obj_label } WHERE { <#{self.uri.to_s}> ?p ?o . ?o <#{RDF::RDFS.label}> ?obj_label }"
    elsif (opts[:predicates] && opts[:predicates].length > 0)      
      construct_query = build_multifield_query(opts[:predicates],"?o")
    else
      construct_query = "CONSTRUCT { ?o ?obj_pred ?obj_label } WHERE { <#{self.uri.to_s}> ?p ?o . ?o ?obj_pred ?obj_label }"
    end

    extra_triples = self.class._graph_of_triples_from_construct_or_describe construct_query
    self.class.add_data_to_repository(extra_triples, self.repository)
  end

  # build a list of optional predicates  
  # 
  # for the input 
  #  build_multifield_query(RDF::SKOS.prefLabel, RDF::RDFS.label, RDF::DC.title],"?p")
  # 
  # the follwing query is generated
  # 
  # CONSTRUCT {
  #  ?p <http://www.w3.org/2004/02/skos/core#prefLabel> ?pref_label . 
  #  ?p <http://www.w3.org/2000/01/rdf-schema#label> ?label . 
  #  ?p <http://purl.org/dc/elements/1.1/title> ?title . }
  #  WHERE {  
  #    <http://data.hampshirehub.net/data/miscelleanous/2011-census-ks101ew-usual-resident-population-key-statistics-ks> ?p ?o .  
  #    OPTIONAL { ?p <http://www.w3.org/2004/02/skos/core#prefLabel> ?pref_label .  } 
  #    OPTIONAL { ?p <http://www.w3.org/2000/01/rdf-schema#label> ?label .  }
  #    OPTIONAL { ?p <http://purl.org/dc/elements/1.1/title> ?title .  } 
  #  }
  # 
  def build_multifield_query(predicates,subject_position_as)
      clauses = []

      iter = 0
      predicates.each do |p|
        variable_name = "var#{iter.to_s}"
        clauses << "#{subject_position_as} <#{p.to_s}> ?#{variable_name} . "   
        iter +=1   
      end

      construct_query = "CONSTRUCT { "
      clauses.each do |c|
        construct_query += c
      end

      construct_query += " } WHERE {  <#{self.uri.to_s}> ?p ?o . "
      clauses.each do |c|
        construct_query += " OPTIONAL { #{c} } "
      end
      construct_query += " }" # close WHERE
  end

  # get the resource that represents a particular uri. If there's triples in our repo where that uri
  # is the subject, use that to hydrate a resource, otherwise justdo a find against the db.
  def get_related_resource(resource_uri, class_of_resource_to_create)
    data_graph = RDF::Graph.new

    self.repository.query( [ RDF::URI.new(resource_uri.to_s), :predicate, :object] ) do |stmt|
      data_graph << stmt
    end

    if data_graph.empty?
      r = nil
    else
      # it's in our eager loaded repo
      r = class_of_resource_to_create.new(resource_uri)
      r.hydrate!(:graph => data_graph)
      r.new_record = false
      r
    end
    r
  end

  def has_related_resource?(resource_uri, class_of_resource)
    !!get_related_resource(resource_uri, class_of_resource)
  end

end