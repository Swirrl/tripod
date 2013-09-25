class Dog

  include Tripod::Resource

  rdf_type 'http://example.com/dog'
  graph_uri 'http://example.com/graph'

  field :name, 'http://example.com/name'

  linked_to :owner, 'http://example.com/owner', class_name: 'Person'
  linked_to :person, 'http://example.com/person'
  linked_to :friends, 'http://example.com/friend', multivalued: true, class_name: 'Dog'
  linked_to :previous_owner, 'http://example.com/prevowner', class_name: 'Person', field_name: :prev_owner_uri

  linked_to :arch_enemy, 'http://example.com/archenemy', class_name: 'Dog'
  linked_to :enemies, 'http://example.com/enemy', class_name: 'Dog'
end