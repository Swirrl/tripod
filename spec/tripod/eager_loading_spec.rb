require "spec_helper"

describe Tripod::EagerLoading do

   before do

    @name = Resource.new('http://example.com/name', 'http://example.com/names')
    @name.label = "Name"
    @name.write_predicate('http://example.com/name-other-pred', 'hello') # another predicate
    @name.save!

    @peter = Person.new('http://example.com/peter')
    @peter.name = "Peter"
    @peter.age = 30
    @peter.save!

    @john = Person.new('http://example.com/john')
    @john.name = "john"
    @john.knows = @peter.uri
    @john.save!
  end

  describe "#eager_load_predicate_triples!" do

    context "with no options passed" do
      before do
        @peter.eager_load_predicate_triples!
      end

      it "should add triples to the repository all for the predicates' predicates" do
        triples = @peter.repository.query([ RDF::URI.new('http://example.com/name'), :predicate, :object] )
        triples.to_a.length.should == 2

        triples.to_a.sort{|a,b| a.to_s <=> b.to_s }.first.predicate.should == RDF::URI('http://example.com/name-other-pred')
        triples.to_a.sort{|a,b| a.to_s <=> b.to_s }.first.object.to_s.should == "hello"

        triples.to_a.sort{|a,b| a.to_s <=> b.to_s }.last.predicate.should == RDF::RDFS.label
        triples.to_a.sort{|a,b| a.to_s <=> b.to_s }.last.object.to_s.should == "Name"
      end
    end

    context "with labels_only option" do
      before do
        @peter.eager_load_predicate_triples!(:labels_only => true)
      end

      it "should add triples to the repository all for the predicates labels only" do
        triples = @peter.repository.query([ RDF::URI.new('http://example.com/name'), :predicate, :object] )
        triples.to_a.length.should == 1
        triples.first.predicate.should == RDF::RDFS.label
        triples.first.object.to_s.should == "Name"
      end

    end

  end

  describe "#eager_load_object_triples!" do

    before do
      @john.eager_load_object_triples!
    end

    it "should add triples to the repository for the all the objects' predicates" do
      triples = @john.repository.query([ @peter.uri, :predicate, :object] )
      triples.to_a.length.should == 3

      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[0].predicate.should ==  RDF::URI('http://example.com/age')
      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[0].object.to_s.should == "30"

      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[1].predicate.should ==  RDF::URI('http://example.com/name')
      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[1].object.to_s.should == "Peter"

      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[2].predicate.should == RDF.type
      triples.to_a.sort{|a,b| a.to_s <=> b.to_s }[2].object.to_s.should == RDF::URI('http://example.com/person')

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

  describe "#has_related_resource?" do

    context "when eager load not called" do
      context "and related resource exists" do
        it "should return false" do
          @john.has_related_resource?(RDF::URI.new('http://example.com/name'), Resource).should be false
        end
      end

      context "and related resource doesn't exist" do
        it "should return false" do
          @john.has_related_resource?(RDF::URI.new('http://example.com/nonexistent/person'), Person).should be false
        end
      end
    end

    context "when eager load called" do
      before do
        @john.eager_load_predicate_triples!
      end

      context "and related resource exists" do
        it "should return true" do
          @john.has_related_resource?(RDF::URI.new('http://example.com/name'), Resource).should be true
        end
      end

      context "and related resource doesn't exist" do
        it "should return false" do
          @john.has_related_resource?(RDF::URI.new('http://example.com/nonexistent/person'), Person).should be false
        end
      end
    end

  end

end