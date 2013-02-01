require "spec_helper"

describe Tripod::Serialization do

  let(:person) do
    p = Person.new('http://garry')
    p.name = 'Garry'
    p.age = 30
    p
  end

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
