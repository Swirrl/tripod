require "spec_helper"

describe Tripod::Repository do

  describe "#hydrate" do

    context 'uri set' do

      before do
        @uri = 'http://foobar'
        @uri2 = 'http://bazbar'
        @graph_uri = 'http://graph'

        p1 = Person.new(@uri, @graph_uri)
        p1.write_predicate('http://pred', RDF::URI.new('http://obj'))
        p1.write_predicate('http://pred2', RDF::URI.new('http://obj2'))
        p1.write_predicate('http://pred3', 'literal')
        p1.save!
      end

      let(:person) do
        Person.new(@uri, @graph_uri)
      end

      context 'no graph passed' do

        context 'no predicate restrictions passed' do

          it 'populates the repository with a graph of triples from the db' do
            Tripod::SparqlClient::Query.should_receive(:describe).with("DESCRIBE <#{@uri}>").and_call_original
            person.hydrate!
            person.repository.should_not be_empty
          end

        end
      end

      context 'graph passed' do
        it 'populates the repository with the graph of triples passed in, ingoring triples not about this resource' do
          @graph = RDF::Graph.new

          person.repository.statements.each do |s|
            @graph << s
          end

          @graph << RDF::Statement.new( 'http://anotherresource', 'http://pred', 'http://obj')
          @graph.statements.count.should ==2 # there'll already be a statement about type in the person.

          person.hydrate!(:graph => @graph)
          person.repository.should_not be_empty
          person.repository.statements.count.should == 1 # not the extra ones
          person.repository.statements.first.should == @graph.statements.first
        end
      end

    end

  end


end