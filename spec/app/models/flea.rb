class Flea
  include Tripod::EmbeddedResource

  rdf_type 'http://example.com/flea'

  field :name, 'http://example.com/flea/name'
  validates_presence_of :name
end
