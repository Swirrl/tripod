require "spec_helper"

describe Tripod::Attributes do

  before do
    @uri = 'http://ric'
    @graph = RDF::Graph.new

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
    p.hydrate!(@graph)
    p
  end

  describe "#[]" do
    it 'returns the values where the predicate matches' do
      values = person['http://blog']
      values.length.should == 2
      values.first.should == RDF::URI('http://blog1')
      values[1].should == RDF::URI('http://blog2')
    end
  end

  describe "#read_attribute" do
    it 'returns the values where the predicate matches' do
      values = person.read_attribute('http://blog')
      values.length.should == 2
      values.first.should == RDF::URI('http://blog1')
      values[1].should == RDF::URI('http://blog2')
    end
  end

  describe '#[]=' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person['http://name'] = 'richard'
        person['http://name'].should == [RDF::Literal.new('richard')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person['http://name'] = ['richard', 'ric', 'ricardo']
        person['http://name'].should == [RDF::Literal.new('richard'), RDF::Literal.new('ric'), RDF::Literal.new('ricardo')]
      end
    end
  end

  describe '#write_attribute' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person.write_attribute('http://name', 'richard')
        person['http://name'].should == [RDF::Literal.new('richard')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person.write_attribute('http://name', ['richard', 'ric', 'ricardo'])
        person['http://name'].should == [RDF::Literal.new('richard'), RDF::Literal.new('ric'), RDF::Literal.new('ricardo')]
      end
    end

  end

  describe '#remove_attribute' do
    it 'remnoves the values where the predicate matches' do
      person.remove_attribute('http://blog')
      person['http://blog'].should be_empty
    end
  end

  describe "append_to_attribute" do

    it 'appends values to the existing values for the predicate' do
      person.append_to_attribute('http://name', 'rico')
      person['http://name'].should == [RDF::Literal.new('ric'), RDF::Literal.new('rico')]
    end

  end

end