require "spec_helper"

describe Tripod::Attributes do

  before do
    @uri = 'http://foobar'
    @graph = RDF::Graph.new

    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@uri)
    stmt.predicate = RDF::URI.new('http://pred')
    stmt.object = RDF::URI.new('http://obj')
    @graph << stmt

    stmt2 = RDF::Statement.new
    stmt2.subject = RDF::URI.new(@uri)
    stmt2.predicate = RDF::URI.new('http://pred')
    stmt2.object = RDF::URI.new('http://obj2')
    @graph << stmt2

    stmt3 = RDF::Statement.new
    stmt3.subject = RDF::URI.new(@uri)
    stmt3.predicate = RDF::URI.new('http://pred')
    stmt3.object = 3
    @graph << stmt3

    stmt4 = RDF::Statement.new
    stmt4.subject = RDF::URI.new(@uri)
    stmt4.predicate = RDF::URI.new('http://pred2')
    stmt4.object = "hello"
    @graph << stmt4
  end

  let(:person) do
    p = Person.new(@uri)
    p.hydrate!(@graph)
    p
  end

  describe "#[]" do
    it 'returns the values where the predicate matches' do
      values = person['http://pred']
      values.length.should == 3
      values.first.should == RDF::URI('http://obj')
      values[1].should == RDF::URI('http://obj2')
      values[2].should == RDF::Literal.new(3)
    end
  end

  describe '#[]=' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person['http://pred2'] = 'goodbye'
        person['http://pred2'].should == [RDF::Literal.new('goodbye')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person['http://pred2'] = ['goodbye', 31, RDF::URI('http://objectio')]
        person['http://pred2'].should == [RDF::Literal.new('goodbye'), RDF::Literal.new(31), RDF::URI('http://objectio')]
      end
    end
  end

  describe '#write_attribute' do

    context 'single term passed' do
      it 'replaces the values where the predicate matches' do
        person.write_attribute('http://pred2', 'goodbye')
        person['http://pred2'].should == [RDF::Literal.new('goodbye')]
      end
    end

    context 'multiple terms passed' do
      it 'replaces the values where the predicate matches' do
        person.write_attribute('http://pred2', ['goodbye', 31, RDF::URI('http://objectio')])
        person['http://pred2'].should == [RDF::Literal.new('goodbye'), RDF::Literal.new(31), RDF::URI('http://objectio')]
      end
    end

  end

  describe '#remove_attribute' do
    it 'remnoves the values where the predicate matches' do
      person.remove_attribute('http://pred2')
      person['http://pred2'].should be_empty
    end
  end

end