class Person

  include Tripod::Resource

  rdf_type 'http://person'
  graph_uri 'http://graph'

  field :name, 'http://name'
  field :father, 'http://father'
  field :knows, 'http://knows', :multivalued => true
  field :aliases, 'http://alias', :multivalued => true
  field :age, 'http://age', :datatype => RDF::XSD.integer
  field :important_dates, 'http://importantdates', :datatype => RDF::XSD.date, :multivalued => true

end