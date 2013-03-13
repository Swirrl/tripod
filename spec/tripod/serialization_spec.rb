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

  context "where no eager loading has happened" do

    describe "#to_rdf" do
      it "should dump the contents of the repository as rdfxml" do
        person.to_rdf.should == person.repository.dump(:rdfxml)
      end
    end

    describe "#to_ttl" do
      it "should dump the contents of the repository with the n3 serializer" do
        person.to_ttl.should == person.repository.dump(:n3)
      end
    end

    describe "#to_nt" do
      it "should dump the contents of the repository as ntriples" do
        person.to_nt.should == person.repository.dump(:ntriples)
      end
    end

     describe "#to_json" do
      it "should dump the contents of the repository as ntriples" do
        person.to_json.should == person.repository.dump(:jsonld)
      end
    end

  end

  context "where eager loading has happened" do

    before do
      person.eager_load_predicate_triples!
      person.eager_load_object_triples!
    end

    describe "#to_rdf" do
      it "should dump the triples for this resource only as rdfxml" do
        person.to_rdf.should == person.get_triples_for_this_resource.dump(:rdfxml)
      end
    end

    describe "#to_ttl" do
      it "should dump the triples for this resource only with the n3 serializer" do
        person.to_ttl.should == person.get_triples_for_this_resource.dump(:n3)
      end
    end

    describe "#to_nt" do
      it "should dump the triples for this resource only as ntriples" do
        person.to_nt.should == person.get_triples_for_this_resource.dump(:ntriples)
      end
    end

     describe "#to_json" do
      it "should dump the triples for this resource only as ntriples" do
        person.to_json.should == person.get_triples_for_this_resource.dump(:jsonld)
      end
    end



  end

end
