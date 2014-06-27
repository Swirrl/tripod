require "spec_helper"

describe Tripod::Predicates do

  before do
    @uri = 'http://example.com/ric'
    @graph = RDF::Graph.new

    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@uri)
    stmt.predicate = RDF::URI.new('http://example.com/blog')
    stmt.object = RDF::URI.new('http://example.com/blog1')
    @graph << stmt

    stmt2 = RDF::Statement.new
    stmt2.subject = RDF::URI.new(@uri)
    stmt2.predicate = RDF::URI.new('http://example.com/blog')
    stmt2.object = RDF::URI.new('http://example.com/blog2')
    @graph << stmt2

    stmt3 = RDF::Statement.new
    stmt3.subject = RDF::URI.new(@uri)
    stmt3.predicate = RDF::URI.new('http://example.com/name')
    stmt3.object = "ric"
    @graph << stmt3

    # throw a random other statement (about name) in the mix!
    stmt4 = RDF::Statement.new
    stmt4.subject = RDF::URI.new('http://example.com/name')
    stmt4.predicate = RDF::RDFS.label
    stmt4.object = "name"
    @graph << stmt4
  end

  let(:person) do
    p = Person.new(@uri)
    p.hydrate!(:graph => @graph)
    p
  end

  describe "#read_predicate" do
    it 'returns the values where the predicate matches' do
      values = person.read_predicate('http://example.com/blog')
      values.length.should == 2
      values.first.should == RDF::URI('http://example.com/blog1')
      values[1].should == RDF::URI('http://example.com/blog2')
    end
  end

  describe '#write_predicate' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person.write_predicate('http://example.com/name', 'richard')
        person.read_predicate('http://example.com/name').should == [RDF::Literal.new('richard')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person.write_predicate('http://example.com/name', ['richard', 'ric', 'ricardo'])
        person.read_predicate('http://example.com/name').should == [RDF::Literal.new('richard'), RDF::Literal.new('ric'), RDF::Literal.new('ricardo')]
      end
    end

    context 'given a nil value' do
      it 'just removes the predicate' do
        person.write_predicate('http://example.com/name', nil)
        person.read_predicate('http://example.com/name').should be_empty
      end
    end
  end

  describe '#remove_predicate' do
    it 'removes the values where the predicate matches' do
      person.remove_predicate('http://example.com/blog')
      person.read_predicate('http://example.com/blog').should be_empty
    end

    context 'when there are other triples in the repository that share the same predicate' do
      let(:subject)   { RDF::URI.new('http://foo') }
      let(:predicate) { RDF::URI.new('http://example.com/blog') }
      before do
        person.repository << [subject, predicate, RDF::URI.new('http://foo.tumblr.com')]
      end

      it "doesn't remove a value where the subject of the triple isn't the resource's URI" do
        person.remove_predicate('http://example.com/blog')
        person.repository.query( [subject, predicate, :object] ).should_not be_empty
      end
    end
  end

  describe "#append_to_predicate" do
    it 'appends values to the existing values for the predicate' do
      person.append_to_predicate('http://example.com/name', 'rico')
      person.read_predicate('http://example.com/name').should == [RDF::Literal.new('ric'), RDF::Literal.new('rico')]
    end
  end

  describe "#predicates" do
    it "returns a list of unique RDF::URIs for the predicates set on this resource" do
      person.predicates.length.should == 2
      person.predicates.should == [RDF::URI('http://example.com/blog'), RDF::URI('http://example.com/name')]
    end


  end

end