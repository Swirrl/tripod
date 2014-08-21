class Resource

  include Tripod::Resource

    field :pref_label, RDF::SKOS.prefLabel
    field :label, RDF::RDFS.label
    field :title, RDF::DC.title

end



