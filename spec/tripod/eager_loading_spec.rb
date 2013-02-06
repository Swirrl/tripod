require "spec_helper"

describe Tripod::EagerLoading do

   before do

    @name = Resource.new('http://name', 'http://names')
    @name.label = "Name"
    @name.save!

    @peter = Person.new('http://peter')
    @peter.name = "Peter"
    @peter.save!

    @john = Person.new('http://john')
    @john.name = "john"
    @john.knows = @peter.uri
    @john.save!
  end

  describe "#eager_load_predicate_triples!" do

    before do
      @peter.eager_load_predicate_triples!
    end

    it "should add triples to the repository for the predicates" do
      triples = @peter.repository.query([ RDF::URI.new('http://name'), :predicate, :object] )
      triples.to_a.length.should_not == 0
      triples.first.predicate.should == RDF::RDFS.label
      triples.first.object.to_s.should == "Name"
    end

  end

  describe "#eager_load_object_triples!" do

    before do
      @john.eager_load_object_triples!
    end

    it "should add triples to the repository for the objects" do
      triples = @john.repository.query([ @peter.uri, :predicate, :object] )
      triples.to_a.length.should_not == 0

      triples.first.predicate.should == RDF.type
      triples.first.object.to_s.should == RDF::URI('http://person')

      triples.to_a[1].predicate.should == RDF::URI('http://name')
      triples.to_a[1].object.to_s.should == "Peter"
    end

  end

  describe "#get_related_resource" do

    context "when eager load not called" do

      context "and related resource exists" do
        it "should return nil" do
          res = @john.get_related_resource(@peter.uri, Person)
          res.should == nil
        end
      end

      context "and related resource doesn't exist" do

        it "should return nil" do
          res = @john.get_related_resource(RDF::URI.new('http://nonexistent/person'), Person)
          res.should be_nil
        end
      end
    end

    context "when eager_load_object_triples has been called" do
      before do
        @john.eager_load_object_triples!
      end

      it "should not call find" do
        Person.should_not_receive(:find)
        @john.get_related_resource(@peter.uri, Person)
      end

      it "should get the right instance of the resource class passed in" do
        res = @john.get_related_resource(@peter.uri, Person)
        res.should == @peter
      end
    end

    context "when eager_load_predicate_triples has been called" do
      before do
        @john.eager_load_predicate_triples!
      end

      it "should not call find" do
        Person.should_not_receive(:find)
        @john.get_related_resource(RDF::URI.new('http://name'), Resource)
      end

      it "should get the right instance of the resource class passed in" do
        res = @john.get_related_resource(RDF::URI.new('http://name'), Resource)
        res.should == @name
      end

      it "should be possible to call methods on the returned object" do
        @john.get_related_resource(RDF::URI.new('http://name'), Resource).label.should == @name.label
      end
    end


  end

end