require "spec_helper"

describe Tripod::SparqlClient do
  describe Data do
    let(:data) { 'some-data-goes-here' }

    describe "Query#query" do
      it "should use Tripod::Streaming to get the data" do
        query = "SELECT * WHERE {?s ?p ?o}"
        Tripod::Streaming.should_receive(:get_data).with(
          Tripod.query_endpoint + "?query=#{CGI.escape(query)}",
          {
            accept: "application/sparql-results+json",
            timeout_seconds: Tripod.timeout_seconds,
            response_limit_bytes: Tripod.response_limit_bytes
          }
        ).and_return("some data")
        Tripod::SparqlClient::Query.query(query, "application/sparql-results+json")
      end
    end

    describe "Data#append" do
      it "should add the graph uri to the configured data endpoint" do
        RestClient::Request.should_receive(:execute).with(hash_including(url: 'http://127.0.0.1:3030/tripod-test/data?graph=http://example.com/foo'))
        Tripod::SparqlClient::Data.append('http://example.com/foo', data)
      end

      it "should send the data as the payload" do
        RestClient::Request.should_receive(:execute).with(hash_including(payload: data))
        Tripod::SparqlClient::Data.append('http://example.com/foo', data)
      end

      it "should HTTP POST the data" do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :post))
        Tripod::SparqlClient::Data.append('http://example.com/foo', data)
      end

      context "which fails with a 400 error" do
        before do
          WebMock.enable!
          stub_http_request(:post, 'http://127.0.0.1:3030/tripod-test/data?graph=http://example.com/foo').to_return(body: 'Error 400: Trousers missing', status: 400)
        end

        it "should raise a 'parse failed' exception" do
          lambda { Tripod::SparqlClient::Data.append('http://example.com/foo', data) }.should raise_error(Tripod::Errors::BadDataRequest)
        end

        after do
          WebMock.disable!
        end
      end
    end

    describe "Data#replace" do
      it "should HTTP PUT the data" do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :put))
        Tripod::SparqlClient::Data.replace('http://example.com/foo', data)
      end
    end
  end
end