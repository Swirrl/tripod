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

    describe '.query' do
      let(:port) { 8080 }
      before do
        @query_endpoint = Tripod.query_endpoint
        Tripod.query_endpoint = "http://localhost:#{port}/sparql/query"
        @server_thread = Thread.new do
          Timeout::timeout(20) do
            listener = TCPServer.new port
            client = listener.accept

            # read request
            loop do
              line = client.gets
              break if line =~ /^\s*$/
            end

            # write response
            client.puts "HTTP/1.1 503 Timeout"
            client.puts "Content-Length: 0"
            client.puts
            client.puts
          end
        end
      end

      after do
        Tripod.query_endpoint = @query_endpoint
        @server_thread.join
      end

      it 'should raise timeout error' do
        expect { Tripod::SparqlClient::Query.query('SELECT * WHERE { ?s ?p ?o }', 'application/n-triples') }.to raise_error(Tripod::Errors::Timeout)
      end
    end
  end
end
