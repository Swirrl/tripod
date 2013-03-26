require "spec_helper"

describe Tripod::Streaming do

  let(:url) { 'http://example.com' }
  let(:response_length) { 64.kilobytes }

  before do
    WebMock.enable!
    stub_http_request(:get, url).with(:headers => {'Accept' => "*/*"}).to_return(:body => ("0" * response_length))
  end

  describe ".get_data" do
    it "should make a request to the url passed in" do
      Tripod::Streaming.get_data(url)
    end

    context "with timeout option" do
      it "should set the read_timeout to that value" do
        Net::HTTP.any_instance.should_receive(:read_timeout=).with(28)
        Tripod::Streaming.get_data(url, :timeout_seconds => 28)
      end
    end

    context "with no timeout option" do
      it "should set the read_timeout to the default (10s)" do
        Net::HTTP.any_instance.should_receive(:read_timeout=).with(10)
        Tripod::Streaming.get_data(url)
      end
    end

    context "with an accept header option" do
      it "should use that header for the request " do
        stub_http_request(:get, url).with(:headers => {'Accept' => "application/json"})
        Tripod::Streaming.get_data(url, :accept => 'application/json')
      end
    end

    # these tests actually download remote resources (from jQuery's CDN) to test the streaming bits
    # TODO: move this out so it doesn't run with the normal rake task??
    context "streaming" do
      before { WebMock.disable! }

      context "with no limit" do

        it "should return the full body" do
          full_response_length = RestClient.get('http://code.jquery.com/jquery-1.9.1.js').body.length
          response = Tripod::Streaming.get_data('http://code.jquery.com/jquery-1.9.1.js')
          response.length.should == full_response_length
        end
      end

      context "with a limit" do
        it "should raise an exception if it's bigger than the limit" do
          unlimited_response = Tripod::Streaming.get_data('http://code.jquery.com/jquery-1.9.1.js')
          unlimited_response.length.should > 48.kilobytes

          lambda {
            Tripod::Streaming.get_data('http://code.jquery.com/jquery-1.9.1.js', :response_limit_bytes => 32.kilobytes)
          }.should raise_error(Tripod::Errors::SparqlResponseTooLarge)
        end
      end
    end
  end

  after do
    WebMock.disable!
  end

end
