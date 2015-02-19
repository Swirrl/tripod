require 'spec_helper'

module Tripod::SparqlClient
  describe Update do
    describe '.update' do
      context 'given a valid SPARQL query' do
        let(:uri) { RDF::URI.new("http://example.com/me") }
        let(:query) { "INSERT DATA { GRAPH <http://example.com/graph/foo> { #{uri.to_base} <http://example.com/hello> \"world\" . } }" }

        it 'should return true' do
          Update.update(query).should == true
        end

        it 'should execute the update' do
          Update.update(query)
          Resource.find(uri).should_not be_nil
        end

        context 'and some additional endpoint params' do
          it 'should include the additional params in the query payload'
        end
      end
    end
  end
end
