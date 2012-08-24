require "spec_helper"

describe Tripod::Persistence do

  describe "#save" do

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
      p = Person.new(@uri)
      Tripod::SparqlClient::Query.should_receive(:describe).at_least(:once).with("DESCRIBE <#{@uri}>").and_return(@graph_nt)
      p.hydrate!
      p
    end

    it 'saves the contents to the db' do
      person.save.should be_true

      # try reading the data back out.
      p2 = Person.new(@uri)
      p2.hydrate!
      repo_statements = p2.repository.statements
      repo_statements.count.should == 1
      repo_statements.first.subject.should == RDF::URI.new(@uri)
      repo_statements.first.predicate.should == RDF::URI.new('http://pred')
      repo_statements.first.object.should == RDF::URI.new('http://obj')
    end

  end

end