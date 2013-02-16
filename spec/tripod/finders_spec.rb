require "spec_helper"

describe Tripod::Finders do

  let(:ric) do
    r = Person.new('http://example.com/people/id/ric')
    r.name = "ric"
    r.knows = RDF::URI.new("http://bill")
    r.save
    r
  end

  let(:bill) do
    b = Person.new('http://example.com/people/id/bill')
    b.name = "bill"
    b.save
    b
  end

  describe '.find' do

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

    context 'with a given graph URI' do

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
      res.first.knows.should == [RDF::URI.new("http://bill")]
    end

    it 'uses the uri and graph variables if supplied' do
      res = Person.where('SELECT ?bob ?geoff WHERE { GRAPH ?geoff { ?bob ?p ?o } }', :uri_variable => 'bob', :graph_variable => 'geoff')
      res.length.should == 2
    end

    it "returns non-new records" do
      res = Person.where('SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }')
      res.first.new_record?.should be_false
    end
  end

  describe '.find_by_type' do

    let(:rdf_type) { RDF::URI(Person._RDF_TYPE) }

    context "passing a string" do
      it "should call .where with a query which restricts to the rdf_type passed in" do
        Resource.should_receive(:where).with("SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <#{rdf_type.to_s}> } }")
        Resource.find_by_type(rdf_type.to_s)
      end
    end

    context "passing an RDF::URI" do
      it "should call .where with a query which restricts to the rdf_type passed in (to_string'd)" do
        Resource.should_receive(:where).with("SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <#{rdf_type.to_s}> } }")
        Resource.find_by_type(rdf_type)
      end
    end

    context "with data in the database" do

      before do
        # save these into the db
        bill
        ric
      end

      it "should return all resources of the type in the database" do
        resources = Resource.find_by_type(rdf_type)
        resources.length.should == 2
      end
    end
  end

  describe '.all' do
    context "with a class level rdf type specified" do
      it "should call .find_by_type, passing the class level rdf_type" do
        Person.should_receive(:find_by_type).with(Person._RDF_TYPE)
        Person.all
      end

      context "with an rdf_type passed in" do
        let(:type_param) { 'http://anothertype' }
        it "should call .where, with a query which restricts to the passed in rdf type" do
          Person.should_receive(:find_by_type).with(type_param)
          Person.all(type_param)
        end
      end
    end


  end


end
