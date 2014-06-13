require "spec_helper"

describe Tripod::Graphs do
  describe "#graphs" do
    let(:uri) { 'http://example.com/foobar' }
    let(:graph_uri) { 'http://example.com/irl' }
    let(:another_graph_uri) { 'http://example.com/make-believe' }
    let(:person) do
      p = Person.new(uri, graph_uri: graph_uri)
      p.write_predicate('http://example.com/vocation', RDF::URI.new('http://example.com/accountant'))
      p.save!
      p
    end

    before do
      p2 = Person.new(uri, graph_uri: another_graph_uri)
      p2.write_predicate('http://example.com/vocation', RDF::URI.new('http://example.com/lion-tamer'))
      p2.save!
      p2
    end

    it 'should return an array of all the graphs for which there are triples about this URI' do
      person.graphs.should =~ [graph_uri, another_graph_uri]
    end
  end
end
