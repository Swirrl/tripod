require "spec_helper"

describe Tripod::Finders do

  let!(:ric) do
    r = Person.new('http://example.com/id/ric')
    r.name = "ric"
    r.knows = RDF::URI.new("http://example.com/id/bill")
    r
  end

  let!(:bill) do
    b = Person.new('http://example.com/id/bill')
    b.name = "bill"
    b
  end

  describe '.find' do

    before do
      ric.save!
      bill.save!
    end

    context 'when record exists' do
      let(:person) { Person.find(ric.uri) }

      it 'hydrates and return an object' do
        person.name.should == "ric"
        person.knows.should == [RDF::URI('http://example.com/id/bill')]
      end

      it 'sets the graph on the instantiated object' do
        person.graph_uri.should_not be_nil
        person.graph_uri.should == RDF::URI("http://example.com/graph")
      end

      it "returns a non-new record" do
        person.new_record?.should be false
      end

    end

    context 'when record does not exist' do
      it 'raises not found' do
        lambda { Person.find('http://example.com/nonexistent') }.should raise_error(Tripod::Errors::ResourceNotFound)
      end
    end

    context 'with graph_uri supplied' do
      let!(:another_person) do
        p = Person.new('http://example.com/anotherperson', :graph_uri => 'http://example.com/graphx')
        p.name = 'a.n.other'
        p.save!
        p
      end

      context 'when there are triples about the resource in that graph' do
        it 'should use that graph to call new' do
          Person.should_receive(:new).with(another_person.uri, :graph_uri => 'http://example.com/graphx').and_call_original
          Person.find(another_person.uri, :graph_uri => 'http://example.com/graphx')
        end

      end

      context 'when there are no triples about the resource in that graph' do
        it 'should raise not found' do
          expect {
            Person.find(another_person.uri, :graph_uri => "http://example.com/graphy")
          }.to raise_error(Tripod::Errors::ResourceNotFound)
        end
      end
    end

    context 'with graph_uri supplied (deprecated)' do
      let!(:another_person) do
        p = Person.new('http://example.com/anotherperson', 'http://example.com/graphx')
        p.name = 'a.n.other'
        p.save!
        p
      end

      context 'when there are triples about the resource in that graph' do
        it 'should use that graph to call new' do
          Person.should_receive(:new).with(another_person.uri, :graph_uri => 'http://example.com/graphx').and_call_original
          Person.find(another_person.uri, 'http://example.com/graphx')
        end

      end

      context 'when there are no triples about the resource in that graph' do
        it 'should raise not found' do
          expect {
            Person.find(another_person.uri, "http://example.com/graphy")
          }.to raise_error(Tripod::Errors::ResourceNotFound)
        end
      end
    end

    context 'with no graph_uri supplied' do
       it 'should look up the graph to call new' do
        ric # trigger the lazy load
        Person.should_receive(:new).with(ric.uri, :graph_uri => Person.get_graph_uri).and_call_original
        Person.find(ric.uri)
      end
    end

    context "looking in any graph" do
      context 'model has no default graph URI' do
        let!(:resource) do
          r = Resource.new('http://example.com/foo', :graph_uri => 'http://example/graph/foo')
          r.label = 'Foo'
          r.save!
          r
        end

        it 'should find a resource regardless of which graph it is in' do
          Resource.find(resource.uri, :ignore_graph => true).should_not be_nil
        end
      end

      context 'model has a default graph URI' do
        let!(:another_person) do
          p = Person.new('http://example.com/anotherperson', :graph_uri => 'http://example.com/graphx')
          p.name = 'a.n.other'
          p.save!
          p
        end

        it 'should override the default graph URI and find the resource regardless' do
          Person.find(another_person.uri, :ignore_graph => true).should_not be_nil
        end

        it 'should return the resource without a graph URI' do
          Person.find(another_person.uri, :ignore_graph => true).graph_uri.should be_nil
        end
      end
    end
  end

  describe ".all" do
    it "should make and return a new criteria for the current class, with a where clause of ?uri ?p ?o already started" do
      Person.all.should == Tripod::Criteria.new(Person).where("?uri ?p ?o")
    end
  end

  describe ".where" do

    let(:criteria) { Person.where("[pattern]") }

    it "should make and return a criteria for the current class" do
      criteria.class.should == Tripod::Criteria
    end

    it "should apply the where clause" do
      criteria.where_clauses.should include("[pattern]")
    end

  end

  describe "count" do
    before do
      ric.save!
      bill.save!
    end

    it "should just call count on the all criteria" do
      all_crit = Tripod::Criteria.new(Person)
      Person.should_receive(:all).and_return(all_crit)
      all_crit.should_receive(:count).and_call_original
      Person.count
    end

    it 'should return the count of all resources of this type' do
      Person.count.should == 2
    end
  end

  describe "first" do
    before do
      ric.save!
      bill.save!
    end

    it "should just call count on the all criteria" do
      all_crit = Tripod::Criteria.new(Person)
      Person.should_receive(:all).and_return(all_crit)
      all_crit.should_receive(:first).and_call_original
      Person.first
    end

    it 'should return the first resources of this type' do
      Person.first.class.should == Person
    end
  end

  describe '.find_by_sparql' do

    before do
      # save these into the db
      bill.save!
      ric.save!
    end

    it 'returns an array of resources which match those in the db' do
      res = Person.find_by_sparql('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } } ORDER BY ?uri')
      res.length.should == 2
      res.should include bill
      res.should include ric

      r = res.last
      r.name.should == "ric"
      r.knows.should == [RDF::URI.new("http://example.com/id/bill")]
    end

    it 'uses the uri and graph variables if supplied' do
      res = Person.find_by_sparql('SELECT ?bob ?geoff WHERE { GRAPH ?geoff { ?bob ?p ?o } }', :uri_variable => 'bob', :graph_variable => 'geoff')
      res.length.should == 2
    end

    it "returns non-new records" do
      res = Person.find_by_sparql('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }')
      res.first.new_record?.should be false
    end

  end


end
