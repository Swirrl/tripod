class Resource

  include Tripod::Resource

  field :label, RDF::RDFS.label

end