class Person

  include Tripod::Resource

  field :name, 'http://name'
  field :aliases, 'http://alias', :multivalued => true
  field :age, 'http://age', :datatype => RDF::XSD.integer
  field :important_dates, 'http://importantdates', :datatype => RDF::XSD.date, :multivalued => true

end