require "spec_helper"

describe Tripod::Streaming do

  let(:url) { 'http://example.com' }
  let(:query) { 'select * where {?s ?p ?o}' }
  let(:response_length) { 64.kilobytes }

  before do
    WebMock.enable!
    stub_http_request(:post, url).with(:body => query, :headers => {'Accept' => "*/*"}).to_return(:body => ("0" * response_length))
  end

  describe ".get_data" do
    it "should make a request to the url passed in" do
      Tripod::Streaming.get_data(url, query)
    end

    context "with timeout option" do
      it "should set the read_timeout to that value" do
        Net::HTTP.any_instance.should_receive(:read_timeout=).with(28)
        Tripod::Streaming.get_data(url, query, :timeout_seconds => 28)
      end
    end

    context "with no timeout option" do
      it "should set the read_timeout to the default (10s)" do
        Net::HTTP.any_instance.should_receive(:read_timeout=).with(10)
        Tripod::Streaming.get_data(url, query)
      end
    end

    context "with an accept header option" do
      it "should use that header for the request " do
        stub_http_request(:post, url).with(:body => query, :headers => {'Accept' => "application/json"})
        Tripod::Streaming.get_data(url, query, :accept => 'application/json')
      end
    end

    describe '.create_http_client' do
      context 'http URI with no options' do
        let(:client) { Tripod::Streaming.create_http_client(URI('http://localhost:8080/sparql/query'), {}) }

        it 'should set host' do
          expect(client.address).to eq('localhost')
        end

        it 'should set port' do
          expect(client.port).to eq(8080)
        end

        it 'should set default read timeout' do
          expect(client.read_timeout).to eq(10)
        end

        it 'should not use ssl' do
          expect(client.use_ssl?).to eq(false)
        end
      end

      context 'https URI with default port' do
        let(:client) { Tripod::Streaming.create_http_client(URI('https://localhost/sparql/query'), {}) }
        it 'should use ssl' do
          expect(client.use_ssl?).to eq(true)
        end
      end

      context 'https with non-default port' do
        let(:client) { Tripod::Streaming.create_http_client(URI('https://localhost:4433/sparql/query'), {}) }
        it 'should use ssl' do
          expect(client.use_ssl?).to eq(true)
        end

        it 'should use specified port' do
          expect(client.port).to eq(4433)
        end
      end

      context 'with read timeout option' do
        let(:read_timeout) { 5 }
        let(:client) { Tripod::Streaming.create_http_client(URI('http://localhost/sparql/query'), {:timeout_seconds => read_timeout}) }

        it 'should set read timeout' do
          expect(client.read_timeout).to eq(read_timeout)
        end
      end
    end

    describe '.create_request' do
      context 'with no user or extra headers' do
        let(:req) { Tripod::Streaming.create_request(URI('http://localhost/sparql/query'), {}) }
        it 'should set accept header' do
          expect(req['accept']).to eq('*/*')
        end
      end

      context 'with no user and extra headers' do
        let!(:extra_headers) { {'content-type' => 'application/sparql-query', 'connection' => 'close'} }
        let!(:req) { Tripod::Streaming.create_request(URI('http://localhost/sparql/query'), {:extra_headers => extra_headers}) }

        it 'should set headers' do
          extra_headers.each do |name, value|
            expect(req[name]).to eq(value)
          end
        end
      end

      context 'with no user and extra headers and accept options' do
        let(:extra_headers) { { 'accept' => 'text/trig' } }
        let(:accept) { 'application/n-triples' }
        let(:req) { Tripod::Streaming.create_request(URI('http://localhost/sparql/query'), {:extra_headers => extra_headers, :accept => accept}) }

        it 'should set accept option as accept header' do
          expect(req['accept']).to eq(accept)
        end
      end

      context 'with user and no headers' do
        let(:req) { Tripod::Streaming.create_request(URI('http://user:password@localhost/sparql/query'), {}) }
        it 'should use basic auth' do
          expect(req['authorization']).to match(/Basic [a-zA-Z0-9+\/=]+/)
        end
      end

      context 'with user and extra Authorization header' do
        let(:extra_headers) { {'content-type' => 'application/sparql-query', 'authorization' => 'Token abcdef'} }
        let(:uri) { URI('http://user:password@localhost/sparql/query') }
        let(:req) { Tripod::Streaming.create_request(uri, {:extra_headers => extra_headers}) }

        it 'should use basic auth' do
          expect(req['authorization']).to match(/Basic [a-zA-Z0-9+\/=]+/)
        end

        it 'should set other extra header' do
          expect(req['content-type']).to eq('application/sparql-query')
        end
      end
    end

    # these tests actually download remote resources (from jQuery's CDN) to test the streaming bits
    # TODO: move this out so it doesn't run with the normal rake task??
    context "streaming" do
      context "with no limit" do
        it "should return the full body" do
          response = Tripod::Streaming.get_data(url, query, :no_response_limit => true)
          response.length.should == response_length
        end
      end

      context "with a limit" do
        it "should raise an exception if it's bigger than the limit" do
          lambda {
            Tripod::Streaming.get_data(url, query, :response_limit_bytes => 32.kilobytes)
          }.should raise_error(Tripod::Errors::SparqlResponseTooLarge)
        end
      end
    end
  end

  after do
    WebMock.disable!
  end

end
