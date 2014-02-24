require "spec_helper"

describe Tripod::Repository do

  describe "#hydrate" do

    context 'uri set' do

      before do
        @uri = 'http://example.com/foobar'
        @uri2 = 'http://example.com/bazbar'
        @graph_uri = 'http://example.com/graph'

        p1 = Person.new(@uri, @graph_uri)
        p1.write_predicate('http://example.com/pred', RDF::URI.new('http://example.com/obj'))
        p1.write_predicate('http://example.com/pred2', RDF::URI.new('http://example.com/obj2'))
        p1.write_predicate('http://example.com/pred3', 'literal')
        p1.save!
      end

      let(:person) do
        Person.new(@uri, @graph_uri)
      end

      let(:graphless_resource) do
        Resource.new(@uri)
      end

      context 'no graph passed' do

        context 'graph_uri set on object' do
          it 'populates the object with triples, restricted to the graph_uri' do
            Tripod::SparqlClient::Query.should_receive(:query).with(
              "CONSTRUCT {<#{person.uri}> ?p ?o} WHERE { GRAPH <#{person.graph_uri}> { <#{person.uri}> ?p ?o } }",
              "application/n-triples").and_call_original
            person.hydrate!
            person.repository.should_not be_empty
          end
        end

        context 'graph_uri not set on object' do
          it 'populates the object with triples, not to a graph' do
            Tripod::SparqlClient::Query.should_receive(:query).with(
              "CONSTRUCT {<#{graphless_resource.uri}> ?p ?o} WHERE { GRAPH ?g { <#{graphless_resource.uri}> ?p ?o } }",
              "application/n-triples").and_call_original
            graphless_resource.hydrate!
            graphless_resource.repository.should_not be_empty
          end
        end

      end

      context 'graph passed' do
        it 'populates the repository with the graph of triples passed in' do
          @graph = RDF::Graph.new

          person.repository.statements.each do |s|
            @graph << s
          end

          @graph << RDF::Statement.new( RDF::URI('http://example.com/anotherresource'), RDF::URI('http://example.com/pred'), RDF::URI('http://example.com/obj'))
          @graph.statements.count.should == 2 # there'll already be a statement about type in the person.

          person.hydrate!(:graph => @graph)
          person.repository.should_not be_empty
          person.repository.statements.count.should == 2 # not the extra ones
          person.repository.statements.to_a.should == @graph.statements.to_a
        end
      end

    end

  end


end