[![Build Status](https://travis-ci.org/Swirrl/tripod.svg?branch=master)](https://travis-ci.org/Swirrl/tripod)

# Tripod

ActiveModel-style Ruby ORM for RDF Linked Data. Works with SPARQL 1.1 HTTP endpoints.

* [ActiveModel](https://github.com/rails/rails/tree/master/activemodel)-compliant interface.
* Inspired by [Durran Jordan's](https://github.com/durran) [Mongoid](http://mongoid.org/en/mongoid/) ORM for [MongoDB](http://www.mongodb.org/), and [Ben Lavender's](https://github.com/bhuga) RDF ORM, [Spira](https://github.com/ruby-rdf/spira).
* Uses [Ruby-RDF](https://github.com/ruby-rdf/rdf) to manage the data internally.

## Quick start, for using in a rails app.

1. Add it to your Gemfile and bundle

        gem tripod

        $ bundle

2. Configure it (in application.rb, or development.rb/production.rb/test.rb)

        # (values shown are the defaults)
        Tripod.configure do |config|
          config.update_endpoint = 'http://127.0.0.1:3030/tripod/update'
          config.query_endpoint = 'http://127.0.0.1:3030/tripod/sparql'
          config.timeout_seconds = 30
        end

3. Include it in your model classes.

        class Person
          include Tripod::Resource

          # these are the default rdf-type and graph for resources of this class
          rdf_type 'http://example.com/person'
          graph_uri 'http://example.com/people'

          field :name, 'http://example.com/name'
          field :knows, 'http://example.com/knows', :multivalued => true, :is_uri => true
          field :aliases, 'http://example.com/alias', :multivalued => true
          field :age, 'http://example.com/age', :datatype => RDF::XSD.integer
          field :important_dates, 'http://example.com/importantdates', :datatype => RDF::XSD.date, :multivalued => true
        end

        # Note: Active Model validations are supported

4. Use it

        uri = 'http://example.com/ric'
        p = Person.new(uri)
        p.name = 'Ric'
        p.age = 31
        p.aliases = ['Rich', 'Richard']
        p.important_dates = [Date.new(2011,1,1)]
        p.save!

        people = Person.all.resources #=> returns all people as an array

        ric = Person.find('http://example.com/ric') #=> returns a single Person object.

## Note:

Tripod doesn't supply a database. You need to install one. I recommend [Fuseki](http://jena.apache.org/documentation/serving_data/index.html), which runs on port 3030 by default.


## Some Other interesting features

## Eager Loading

        asa = Person.find('http://example.com/asa')
        ric = Person.find('http://example.com/ric')
        ric.knows = asa.uri

        ric.eager_load_predicate_triples! #does a big DESCRIBE statement behind the scenes
        knows = ric.get_related_resource('http://example.com/knows', Resource)
        knows.label # this won't cause another database lookup

        ric.eager_load_object_triples! #does a big DESCRIBE statement behind the scenes
        asa = ric.get_related_resource('http://example.com/asa', Person) # returns a fully hydrated Person object for asa, without an extra lookup

## Defining a graph at instantiation-time

        class Resource
          include Tripod::Resource
          field :label, RDF::RDFS.label

          # notice also that you don't need to supply an rdf type or graph here!
        end

        r = Resource.new('http://example.com/foo', 'http://example.com/mygraph')
        r.label = "example"
        r.save

        # Note: Tripod assumes you want to store all resources in named graphs.
        # So if you don't supply a graph at any point (i.e. class or instance level),
        # you will get an error when you try to persist the resource.

## Reading and writing arbitrary predicates

        r.write_predicate(RDF.type, 'http://example.com/myresource/type')
        r.read_predicate(RDF.type) #=> [RDF::URI.new("http://example.com/myresource/type")]

## Finders and criteria

        # A Tripod::Criteria object defines a set of constraints for a SPARQL query.
        # It doesn't actually do anything against the DB until you run resources, first, or count on it.
        # (from Tripod::CriteriaExecution)

        Person.all #=> returns a Tripod::Criteria object which selects all resources of rdf_type http://example.com/person, in the http://example.com/people graph

        Resource.all #=> returns a criteria object to return resources in the database (as no rdf_type or graph_uri specified at class level)

        Person.all.resources #=> returns all the actual resources for the criteria object, as an array-like object

        Person.all.resources(:return_graph => false) #=> returns the actual resources, but without returning the graph_uri in the select (helps avoid pagination issues). Note: doesn't set the graph uri on the instantiated resources.

        Person.first #=> returns the first person (by crafting a sparql query under the covers that only returns 1 result)

        Person.first(:return_graph => false) # as with resources, doesn't return / set the graph_uri.

        Person.count  #=> returns the count of all people (by crafting a count query under the covers that only returns a count)

        # note that you need to use ?uri as the variable for the subject.
        Person.where("?uri <http://example.com/name> 'Joe'") #=> returns a Tripod::Criteria object

        Resource.graph("http://example.com/mygraph") #=> Retruns a criteria object with a graph restriction (note: if graph_uri set on the class, it will default to using this)

        Resource.find_by_sparql('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }') #=> allows arbitrary sparql. Again, use ?uri for the variable of the subjects (and ?graph for the graph).

## Chainable criteria

        Person.all.where("?uri <http://example.com/name> 'Ric'").where("?uri <http://example.com/knows> <http://example.com/asa>).first

        Person.where("?uri <http://example.com/name> ?name").limit(1).offset(0).order("DESC(?name)")

## Running tests

With a Fuseki instance ready and up, edit the config in `spec/spec_helper.rb` to reflect your settings. Make sure you `bundle` to pull in all dependencies before trying to run the tests.

Some tests require memcached to be set up and running. The tests that require memcached are tagged with `:caching_tests => true`; do with this information what you will. 

[Full Documentation](http://rubydoc.info/gems/tripod/frames)

Copyright (c) 2012 [Swirrl IT Limited](http://swirrl.com). Released under MIT License