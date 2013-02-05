require "spec_helper"

describe Tripod::Predicates do

  before do
    @uri = 'http://ric'
    @graph = RDF::Graph.new('http://graph')

    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@uri)
    stmt.predicate = RDF::URI.new('http://blog')
    stmt.object = RDF::URI.new('http://blog1')
    @graph << stmt

    stmt2 = RDF::Statement.new
    stmt2.subject = RDF::URI.new(@uri)
    stmt2.predicate = RDF::URI.new('http://blog')
    stmt2.object = RDF::URI.new('http://blog2')
    @graph << stmt2

    stmt3 = RDF::Statement.new
    stmt3.subject = RDF::URI.new(@uri)
    stmt3.predicate = RDF::URI.new('http://name')
    stmt3.object = "ric"
    @graph << stmt3
  end

  let(:person) do
    p = Person.new(@uri)
    p.hydrate!(:graph => @graph)
    p
  end

  describe "#read_predicate" do
    it 'returns the values where the predicate matches' do
      values = person.read_predicate('http://blog')
      values.length.should == 2
      values.first.should == RDF::URI('http://blog1')
      values[1].should == RDF::URI('http://blog2')
    end
  end

  describe '#write_predicate' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person.write_predicate('http://name', 'richard')
        person.read_predicate('http://name').should == [RDF::Literal.new('richard')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person.write_predicate('http://name', ['richard', 'ric', 'ricardo'])
        person.read_predicate('http://name').should == [RDF::Literal.new('richard'), RDF::Literal.new('ric'), RDF::Literal.new('ricardo')]
      end
    end

  end

  describe '#remove_predicate' do
    it 'remnoves the values where the predicate matches' do
      person.remove_predicate('http://blog')
      person.read_predicate('http://blog').should be_empty
    end
  end

  describe "#append_to_predicate" do
    it 'appends values to the existing values for the predicate' do
      person.append_to_predicate('http://name', 'rico')
      person.read_predicate('http://name').should == [RDF::Literal.new('ric'), RDF::Literal.new('rico')]
    end
  end

  describe "#predicates" do
    it "returns a list of unique RDF::URIs for the predicates set on this resource" do
      person.predicates.length.should == 2
      person.predicates.should == [RDF::URI('http://blog'), RDF::URI('http://name')]
    end
  end

end