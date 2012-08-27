require "spec_helper"

describe Tripod::Repository do

  describe "#hydrate" do

    context 'no uri set' do
      let(:person) do
        Person.new
      end

      it 'rasies a UriNotSet error' do
        lambda { person.hydrate! }.should raise_error(Tripod::Errors::UriNotSet)
      end
    end

    context 'uri set' do

      before do
        @uri = 'http://foobar'
        @graph = RDF::Graph.new
        @stmt = RDF::Statement.new
        @stmt.subject = RDF::URI.new(@uri)
        @stmt.predicate = RDF::URI.new('http://pred')
        @stmt.object = RDF::URI.new('http://obj')
        @graph << @stmt
        @graph_nt = @graph.dump(:ntriples)
      end

      let(:person) do
        Person.new(@uri)
      end

      context 'no graph passed' do
        it 'populates the repository with a graph of triples from the db' do
          Tripod::SparqlClient::Query.should_receive(:describe).with("DESCRIBE <#{@uri}>").and_return(@graph_nt)
          person.hydrate!
          person.repository.should_not be_empty
        end
      end

      context 'graph passed' do
        it 'populates the repository with the graph of triples passed in, ingoring triples not about this resource' do

          @graph << RDF::Statement.new( 'http://anotherresource', 'http://pred', 'http://obj')
          @graph.statements.count.should ==2

          person.hydrate!(@graph)
          person.repository.should_not be_empty
          person.repository.statements.count.should == 1 # not the extra one.
          person.repository.statements.first.should == @stmt
        end
      end

    end

  end


end