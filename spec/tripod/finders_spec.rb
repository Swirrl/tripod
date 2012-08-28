require "spec_helper"

describe Tripod::Finders do

  let(:ric) do
    @ric_uri = 'http://ric'
    stmts = RDF::Graph.new

    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@ric_uri)
    stmt.predicate = RDF::URI.new('http://name')
    stmt.object = "ric"
    stmts << stmt

    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@ric_uri)
    stmt.predicate = RDF::URI.new('http://knows')
    stmt.object = RDF::URI.new('http://bill')
    stmts << stmt

    r = Person.new(@ric_uri, 'http://people')
    r.hydrate!(stmts)
    r.save
    r
  end

  let(:bill) do
    @bill_uri = 'http://bill'
    stmts = RDF::Graph.new
    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@bill_uri)
    stmt.predicate = RDF::URI.new('http://name')
    stmt.object = "bill"
    stmts << stmt
    b = Person.new(@bill_uri, 'http://people')
    b.hydrate!(stmts)
    b.save
    b
  end

  describe '.find' do

    context 'when record exists' do

      it 'does not error' do
        r = Person.find(ric.uri)
      end

      it 'hydrates and return an object' do
        r = Person.find(ric.uri)
        r['http://name'].should == [RDF::Literal.new("ric")]
        r['http://knows'].should == [RDF::URI.new('http://bill')]
      end

      it 'sets the graph on the instantiated object' do
        r = Person.find(ric.uri)
        r.graph_uri.should_not be_nil
        r.graph_uri.should == RDF::URI("http://people")
      end

    end

    context 'when record does not exist' do
      it 'raises not found' do
        lambda { Person.find('http://nonexistant') }.should raise_error(Tripod::Errors::ResourceNotFound)
      end
    end

  end

  describe '.where' do

    before do
      # save these into the db
      bill
      ric
    end

    it 'returns an array of resources which match those in the db' do
      res = Person.where('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }')
      res.length.should == 2
      res.first.should == ric
      res.last.should == bill

      res.first.name.should == "ric"
      res.first['http://knows'].should == [RDF::URI.new("http://bill")]
    end

    it 'uses the uri and graph variables if supplied' do
      res = Person.where('SELECT ?bob ?geoff WHERE { GRAPH ?geoff { ?bob ?p ?o } }', :uri_variable => 'bob', :graph_variable => 'geoff')
      res.length.should == 2
    end

  end

end
