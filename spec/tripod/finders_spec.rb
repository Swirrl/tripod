require "spec_helper"

describe Tripod::Finders do

  let(:ric) do
    r = Person.new('http://example.com/people/id/ric')
    r.name = "ric"
    r.knows = RDF::URI.new("http://bill")
    r
  end

  let(:bill) do
    b = Person.new('http://example.com/people/id/bill')
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
        person.knows.should == [RDF::URI('http://bill')]
      end

      it 'sets the graph on the instantiated object' do
        person.graph_uri.should_not be_nil
        person.graph_uri.should == RDF::URI("http://graph")
      end

      it "returns a non-new record" do
        person.new_record?.should be_false
      end

    end

    context 'when record does not exist' do
      it 'raises not found' do
        lambda { Person.find('http://nonexistent') }.should raise_error(Tripod::Errors::ResourceNotFound)
      end
    end

    context 'with graph_uri supplied' do
      it 'should use that graph to call new' do
        ric # trigger the lazy load
        Person.should_receive(:new).with(ric.uri, 'http://graphx').and_call_original
        Person.find(ric.uri, "http://graphx")
      end
    end

    context 'with no graph_uri supplied' do
       it 'should look up the graph to call new' do
        ric # trigger the lazy load
        Person.should_receive(:new).with(ric.uri, Person._GRAPH_URI).and_call_original
        Person.find(ric.uri, Person._GRAPH_URI)
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
      Person.first.should == ric
    end
  end

  describe '.find_by_sparql' do

    before do
      # save these into the db
      bill.save!
      ric.save!
    end

    it 'returns an array of resources which match those in the db' do
      res = Person.find_by_sparql('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }')
      res.length.should == 2
      res.first.should == ric
      res.last.should == bill

      res.first.name.should == "ric"
      res.first.knows.should == [RDF::URI.new("http://bill")]
    end

    it 'uses the uri and graph variables if supplied' do
      res = Person.find_by_sparql('SELECT ?bob ?geoff WHERE { GRAPH ?geoff { ?bob ?p ?o } }', :uri_variable => 'bob', :graph_variable => 'geoff')
      res.length.should == 2
    end

    it "returns non-new records" do
      res = Person.find_by_sparql('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }')
      res.first.new_record?.should be_false
    end

  end


end
