require "spec_helper"

describe Tripod::SparqlClient do
  describe Data do
    let(:data) { 'some-data-goes-here' }

    describe "Data#append" do
      it "should add the graph uri to the configured data endpoint" do
        RestClient::Request.should_receive(:execute).with(hash_including(url: 'http://127.0.0.1:3030/tripod-test/data?graph=http://foo'))
        Tripod::SparqlClient::Data.append('http://foo', data)
      end

      it "should send the data as the payload" do
        RestClient::Request.should_receive(:execute).with(hash_including(payload: data))
        Tripod::SparqlClient::Data.append('http://foo', data)
      end

      it "should HTTP POST the data" do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :post))
        Tripod::SparqlClient::Data.append('http://foo', data)
      end

      context "which fails with a parse error" do
        before do
          WebMock.enable!
          stub_http_request(:post, 'http://127.0.0.1:3030/tripod-test/data?graph=http://foo').to_return(body: 'Error 400: Parse error: Trousers missing', status: 400)
        end

        it "should raise a 'parse failed' exception" do
          lambda { Tripod::SparqlClient::Data.append('http://foo', data) }.should raise_error(Tripod::Errors::RdfParseFailed)
        end

        after do
          WebMock.disable!
        end
      end
    end

    describe "Data#replace" do
      it "should HTTP PUT the data" do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :put))
        Tripod::SparqlClient::Data.replace('http://foo', data)
      end
    end
  end
end