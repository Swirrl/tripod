# Tripod

ActiveModel-style Ruby ORM for RDF data. Works with SPARQL 1.1 HTTP endpoints.

## Quick start, for using in a rails app.

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

          field :name, 'http://name'
          field :aliases, 'http://alias', :multivalued => true
          field :age, 'http://age', :datatype => RDF::XSD.integer
          field :important_dates, 'http://importantdates', :datatype => RDF::XSD.date, :multivalued => true
        end

5. Use it

        uri = 'http://ric'
        graph = 'http://people'
        p = Person.new(uri, graph)
        p.name = 'Ric'
        p.age = 31
        p.aliases = ['Rich', 'Richard']
        p.important_dates = [Date.new(2011,1,1)]
        p[RDF::type] = RDF::URI('http://person')
        p.save!

        people = Person.where("
          SELECT ?person ?graph
          WHERE {
            GRAPH ?graph {
              ?person ?p ?o .
              ?person a <http://person> .
            }
          }",
        :uri_variable => 'person' )
        # => returns an array of Person objects, containing all data we know about them.

        ric = Person.find('http://ric')
        # => returns a single Person object.

[Full Documentation](http://rubydoc.info/github/Swirrl/tripod/master/frames)

__Warning: Work still in progress / experimental. Not production ready!__

Heavily inspired by [Durran Jordan's](https://github.com/durran) excellent [Mongoid](http://mongoid.org/en/mongoid/) ORM for [MongoDB](http://www.mongodb.org/).

Copyright (c) 2012 [Swirrl IT Limited](http://swirrl.com). Released under MIT License