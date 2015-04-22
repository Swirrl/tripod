require "spec_helper"

describe Tripod::Resource do

  describe "#initialize" do

    it "should raise an error if the URI is given as nil" do
      lambda { Person.new(nil) }.should raise_error(Tripod::Errors::UriNotSet)
    end

    context 'with a URI' do
      let(:person) do
        Person.new('http://example.com/foobar')
      end

      it 'sets the uri instance variable' do
        person.uri.should == RDF::URI.new('http://example.com/foobar')
      end

      it 'sets the graph_uri instance variable from the class by default' do
        person.graph_uri.should == RDF::URI.new('http://example.com/graph')
      end

      context "with rdf_type specified at class level" do
        it "sets the rdf type from the class" do
          person.rdf_type.should == [RDF::URI.new('http://example.com/person')]
        end
      end

      it "initialises a repo" do
        person.repository.class.should == RDF::Repository
      end
    end

    context 'with a URI and a graph URI' do
      let(:person) do
        Person.new('http://example.com/foobar', :graph_uri => 'http://example.com/foobar/graph')
      end

      it "overrides the default graph URI with what's given" do
        person.graph_uri.should == RDF::URI.new('http://example.com/foobar/graph')
      end
    end

    context 'with a URI, ignoring the graph URI' do
      let(:person) do
        Person.new('http://example.com/foobar', :ignore_graph => true)
      end

      it "should ignore the class-level graph URI" do
        person.graph_uri.should be_nil
      end
    end
  end

  describe "#<=>" do

    let(:person) do
      Person.new('http://example.com/foobar', :graph_uri => 'http://example.com/foobar/graph')
    end

    let(:person_two) do
      Person.new('http://example.com/foobay', :graph_uri => 'http://example.com/foobar/graph')
    end

    let(:person_three) do
      Person.new('http://example.com/foobaz', :graph_uri => 'http://example.com/foobar/graph')
    end

    it "should sort the resources" do
      [person_two, person_three, person].sort { |a,b| a <=> b }.should eq [person, person_two, person_three]
    end

  end

  describe "#==" do

    let(:person) do
      Person.new('http://example.com/foobar', :graph_uri => 'http://example.com/foobar/graph')
    end

    let(:person_two) do
      Person.new('http://example.com/foobay', :graph_uri => 'http://example.com/foobar/graph')
    end

    it "correctly identifies the same resource" do
      (person == person).should be true
    end

    it "identifies two instances of the same class" do
      person.class.name.should == person_two.class.name
      (person == person_two).should be false
    end

  end
end