# Tripod

ActiveModel-style Ruby ORM for RDF Linked Data. Works with SPARQL 1.1 HTTP endpoints.

* [ActiveModel](https://github.com/rails/rails/tree/master/activemodel)-compliant interface.
* Inspired by [Durran Jordan's](https://github.com/durran) [Mongoid](http://mongoid.org/en/mongoid/) ORM for [MongoDB](http://www.mongodb.org/), and [Ben Lavender's](https://github.com/bhuga) RDF ORM, [Spira](https://github.com/ruby-rdf/spira).
* Uses [Ruby-RDF](https://github.com/ruby-rdf/rdf) to manage the data internally.

## Quick start, for using in a rails app.

Note: Tripod doesn't supply a database. You need to install one. I recommend [Fuseki](http://jena.apache.org/documentation/serving_data/index.html), which runs on port 3030 by default.

1. Install the gem:

        gem install tripod

2. Add it to your Gemfile

        gem tripod

3. Configure it (in application.rb, or development.rb/production.rb/test.rb)

        # (values shown are the defaults)
        Tripod.configure do |config|
          config.update_endpoint = 'http://127.0.0.1:3030/tripod/update'
          config.query_endpoint = 'http://127.0.0.1:3030/tripod/sparql'
          config.timeout_seconds = 30
        end

4. Include it in your model classes.

        class Person
          include Tripod::Resource

          # these are the default rdf-type and graph for resources of this class
          rdf_type 'http://person'
          graph_uri 'http://people'

          field :name, 'http://name'
          field :knows, 'http://knows', :multivalued => true
          field :aliases, 'http://alias', :multivalued => true
          field :age, 'http://age', :datatype => RDF::XSD.integer
          field :important_dates, 'http://importantdates', :datatype => RDF::XSD.date, :multivalued => true
        end

        # Note: Active Model validations are supported

5. Use it

        uri = 'http://ric'
        p = Person.new(uri)
        p.name = 'Ric'
        p.age = 31
        p.aliases = ['Rich', 'Richard']
        p.important_dates = [Date.new(2011,1,1)]
        p.save!

        # Note: queries supplied to the where method should return the uris of the resource,
        # and what graph they're in.
        people = Person.where("
          SELECT ?person ?graph
          WHERE {
            GRAPH ?graph {
              ?person ?p ?o .
              ?person a <http://person> .
            }
          }",
        :uri_variable => 'person' ) # optionally, set a different name for the uri parameter (default: uri)
        # => returns an array of Person objects, containing all data we know about them.

        ric = Person.find('http://ric')
        # => returns a single Person object.

## Some Other interesting features

## Eager Loading

        asa = Person.find('http://asa')
        ric = Person.find('http://ric')
        ric.knows = asa.uri

        ric.eager_load_predicate_triples! #does a big DESCRIBE statement behind the scenes
        knows = ric.get_related_resource('http://knows', Resource)
        knows.label # this won't cause another database lookup

        ric.eager_load_object_triples! #does a big DESCRIBE statement behind the scenes
        asa = ric.get_related_resource('http://knows', Person) # returns a fully hydrated Person object for asa, without an extra lookup

## Defining a graph at instantiation-time

        class Resource
          field :label RDF::RDFS.label

          # notice also that you don't need to supply an rdf type or graph here!
        end

        r = Resource.new('http://foo', 'http://mygraph')

        # if you don't supply a graph at any point, you will get an error when you try to persist the resource.

## Reading and writing arbitrary predicates

        r.write_predicate(RDF.type, 'http://myresource/type')
        r.read_predicate(RDF.type) # => RDF::URI.new("http://myresource/type")



[Full Documentation](http://rubydoc.info/gems/tripod/frames)

Copyright (c) 2012 [Swirrl IT Limited](http://swirrl.com). Released under MIT License