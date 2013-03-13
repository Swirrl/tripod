require "spec_helper"

describe Tripod::EagerLoading do

   before do

    @name = Resource.new('http://example.com/name', 'http://example.com/names')
    @name.label = "Name"
    @name.save!

    @peter = Person.new('http://example.com/peter')
    @peter.name = "Peter"
    @peter.save!

    @john = Person.new('http://example.com/john')
    @john.name = "john"
    @john.knows = @peter.uri
    @john.save!
  end

  describe "#eager_load_predicate_triples!" do

    before do
      @peter.eager_load_predicate_triples!
    end

    it "should add triples to the repository for the predicates" do
      triples = @peter.repository.query([ RDF::URI.new('http://example.com/name'), :predicate, :object] )
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

      triples.to_a[1].predicate.should == RDF.type
      triples.to_a[1].object.to_s.should == RDF::URI('http://example.com/person')

      triples.to_a[0].predicate.should == RDF::URI('http://example.com/name')
      triples.to_a[0].object.to_s.should == "Peter"
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
          res = @john.get_related_resource(RDF::URI.new('http://example.com/nonexistent/person'), Person)
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
        @john.get_related_resource(RDF::URI.new('http://example.com/name'), Resource)
      end

      it "should get the right instance of the resource class passed in" do
        res = @john.get_related_resource(RDF::URI.new('http://example.com/name'), Resource)
        res.should == @name
      end

      it "should be possible to call methods on the returned object" do
        @john.get_related_resource(RDF::URI.new('http://example.com/name'), Resource).label.should == @name.label
      end
    end


  end

end