# Tripod

Coming soon: Active Model style Ruby ORM for RDF data.

## proposed API

    class Person

      include Tripod::Resource

      # literal values
      field :label, :predicate_uri => ['http://blah', 'http://blah2'], :type => String
      field :value, :predicate_uri => 'http://observed-value.com', :type => Integer

      # relationships
      has_one :dataset, :predicate_uri => 'http://void#datset', :type => Dataset
      has_one :spouse,  :predicate_uri =>'http://foaf#spouse', :type => Person
      has_many :friends, :predicate_uri => 'http://foaf#knows', :type => Person

      # this indicates that the predicates are defined on another resource, and this is the object of the triple.
      has_many :known_bys, :predicate_uri => 'http://foaf#knows', :incoming => true, :type => Person
      has_one :benefactor, :predicate_uri => 'http://donates-money-to', :incoming => true, :type => Person

    end


    Person.new(uri)
    # => just instantiates. No data set

    Person.new(uri, RDF::Graph)
    #=> instantiates. Populates data using statements in a graph. Possibly allow to just pass a hash as 2nd param instead?

    Person.find(uri)
    # => finds resource in db, does a describe to populate data. Raises exception if not found
    Person.find(uri1, uri2)
    # => finds resources in db, and does a single describe to populate data. returns collection of resources. Raises exception if any uri not found

    Person.where(sparql, :uri_variable => 'my_uri')
    # => returns a collection of resources, all with their data pre-populated.
         The sparql query should just return unique URIs. Use this to do a big describe.
         Optionally pass the name of the uri variable in the query, if not '?uri'

    # Eager loading, to avoid the n+1 issue
    Person.includes(:datasets).each do |person|
      person.dataset.label # doesn't hit the database again.
    end

    # idea: special 'includes' of :all for all target associations ?
    Person.includes(:all).each do |person|
      person['http://foo'].label
    end

    Person.predicates
    # => returns a collection of resources, which are the resources for the uris of the predicates, if they exist.
    # have a special Predicate class, with a label field.
    # (possibly outside scope of this library).

    p = Person.new('http://swirrl.com/bill.rdf#me')
    p.label = 'Bill'
    p.save # => creates a new record

    p = Person.find('http://swirrl.com/ric.rdf#me')
    p.label = 'Ric'
    p.save # updates the existing record

