require "spec_helper"

describe Tripod::SparqlClient do
  describe Data do

    let(:data) { 'some-data-goes-here' }

    describe "Query#query" do

      let(:query) { "SELECT * WHERE {?s ?p ?o}" }
      let(:bad_query) { "SELECT * WHERE ?s ?p ?o}" }

      before do
        p = Person.new('http://example.com/id/garry')
        p.name = "garry"
        p.save!
        p
      end

      describe "using Tripod::Streaming to get the data" do
        before(:each) do
          Tripod::Streaming.stub(get_data: "some data")
        end

        example do
          Tripod::SparqlClient::Query.query(query, "application/sparql-results+json")

          expect(Tripod::Streaming).to have_received(:get_data).with(
            Tripod.query_endpoint,
            "query=#{CGI.escape(query)}",
            {
              accept: "application/sparql-results+json",
              timeout_seconds: Tripod.timeout_seconds,
              response_limit_bytes: Tripod.response_limit_bytes
            }
          )
        end

        context "with an integer response limit (number of bytes)" do
          it "uses the limit" do
            Tripod::SparqlClient::Query.query(
              query, "application/sparql-results+json", {}, 1024
            )

            expect(Tripod::Streaming).to have_received(:get_data).with(
              kind_of(String), kind_of(String), hash_including(response_limit_bytes: 1024)
            )
          end
        end

        context "with a :default response limit" do
          it "uses the Tripod response limit" do
            Tripod::SparqlClient::Query.query(
              query, "application/sparql-results+json", {}, :default
            )

            expect(Tripod::Streaming).to have_received(:get_data).with(
              kind_of(String), kind_of(String), hash_including(:response_limit_bytes)
            )
          end
        end

        context "with a :no_response_limit response limit" do
          it "doesn't pass a limit" do
            Tripod::SparqlClient::Query.query(
              query, "application/sparql-results+json", {}, :no_response_limit
            )

            expect(Tripod::Streaming).to have_received(:get_data).with(
              kind_of(String), kind_of(String), hash_not_including(:response_limit_bytes)
            )
          end
        end
      end

      it "should execute the query and return the format requested" do
        JSON.parse(Tripod::SparqlClient::Query.query(query, "application/sparql-results+json"))["results"]["bindings"].length > 0
      end

      context "with a bad query" do
        it "should raise a bad request error" do
          lambda {
            Tripod::SparqlClient::Query.query(bad_query, "application/sparql-results+json")
          }.should raise_error
        end
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