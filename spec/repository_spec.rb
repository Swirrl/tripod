require "spec_helper"

describe Tripod::Repository do

  describe "#hydrate" do

    context 'no uri set' do
      let(:person) do
        Person.new
      end

      it 'does nothing' do
        person.hydrate!
        person.repository.should be_empty
      end
    end

    context 'graph passed' do
      it 'should use the graph data'
    end

    context 'uri set' do

      before do
        @uri = 'http://foobar'
        graph = RDF::Graph.new
        stmt = RDF::Statement.new
        stmt.subject = RDF::URI.new(@uri)
        stmt.predicate = RDF::URI.new('http://pred')
        stmt.object = RDF::URI.new('http://obj')
        graph << stmt
        @graph_nt = graph.dump(:ntriples)
      end

      let(:person) do
        Person.new(@uri)
      end

      it 'populates the repository with a graph of triples from the db' do
        Tripod::SparqlClient::Query.should_receive(:describe).with("DESCRIBE <#{@uri}>").and_return(@graph_nt)
        person.hydrate!
        person.repository.should_not be_empty
      end

    end

  end


end