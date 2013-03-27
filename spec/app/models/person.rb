class Person

  include Tripod::Resource

  rdf_type 'http://example.com/person'
  graph_uri 'http://example.com/graph'

  field :name, 'http://example.com/name'
  field :father, 'http://example.com/father', :is_uri => true
  field :knows, 'http://example.com/knows', :multivalued => true
  field :aliases, 'http://exmample.com/alias', :multivalued => true
  field :age, 'http://example.com/age', :datatype => RDF::XSD.integer
  field :important_dates, 'http://example.com/importantdates', :datatype => RDF::XSD.date, :multivalued => true

  before_save :pre_save
  before_destroy :pre_destroy

  def pre_save;; end
  def pre_destroy;; end
end