require "spec_helper"

describe Tripod::Serialization do

  let(:person) do

    p2 = Person.new('http://example.com/fred')
    p2.name = "fred"
    p2.save!

    p = Person.new('http://example.com/garry')
    p.name = 'Garry'
    p.age = 30
    p.knows = p2.uri
    p
  end

  shared_examples_for "a serialisable resource" do
    describe "#to_rdf" do
      it "should get the data from the database as rdf/xml" do
        person.to_rdf.should == person.retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.RDFXml)
      end
    end

    describe "#to_ttl" do
      it "should get the data from the database as text/turtle" do
        person.to_ttl.should == person.retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.Turtle)
      end
    end

    describe "#to_nt" do
      it "should get the data from the database as application/n-triples" do
        person.to_nt.should == person.retrieve_triples_from_database(accept_header=Tripod::Http::ContentType.NTriples)
      end
    end

    describe "#to_json" do
      it "should dump the triples for this resource only as json-ld" do
        person.to_json.should == person.get_triples_for_this_resource.dump(:jsonld)
      end
    end
  end

  context "where no eager loading has happened" do
    it_should_behave_like "a serialisable resource"
  end

  context "where eager loading has happened" do

    before do
      person.eager_load_predicate_triples!
      person.eager_load_object_triples!
    end

    it_should_behave_like "a serialisable resource"

  end

end
