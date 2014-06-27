require "spec_helper"

describe Tripod::CacheStores, :caching_tests => true do

  let(:query) { "SELECT * WHERE {?s ?p ?o}" }
  let(:accept_header) { "application/sparql-results+json" }
  let(:params) { {:query => query}.to_query }
  let(:streaming_opts) { {:accept => accept_header, :timeout_seconds => Tripod.timeout_seconds} }

  before do
    Tripod.cache_store = Tripod::CacheStores::MemcachedCacheStore.new('localhost:11211', 10)

    p = Person.new('http://example.com/id/garry')
    p.name = "garry"
    p.save!
    p
  end

  # if Tripod cache_store is not reset to nil, other tests will fail due to caching
  after(:all) do
    Tripod.cache_store = nil
  end

  describe "sending a query with caching enabled" do
    before do
      @query_result = Tripod::SparqlClient::Query.query(query, accept_header)
      @cache_key = 'SPARQL-QUERY-' + Digest::SHA2.hexdigest([accept_header, query].join("-"))
      @stream_data = -> { Tripod::Streaming.get_data(Tripod.query_endpoint, params, streaming_opts) }
    end

    it "should set the data in the cache" do 
      Tripod.cache_store.fetch(@cache_key, &@stream_data).should_not be_nil
    end

    describe "with a large number of subsequent requests" do
      before do
        @number_of_memcache_get_calls = Tripod.cache_store.stats[0]["localhost:11211"]["cmd_get"]
        @number_of_memcache_set_calls = Tripod.cache_store.stats[0]["localhost:11211"]["cmd_set"]

        100.times do
          Thread.new do
            Tripod::SparqlClient::Query.query(query, accept_header)
          end
        end
      end

      it "should increase number of memcache get calls" do
        Tripod.cache_store.stats[0]["localhost:11211"]["cmd_get"].to_i.should be > @number_of_memcache_get_calls.to_i
      end

      it "should not increase cache size" do
        Tripod.cache_store.stats[0]["localhost:11211"]["cmd_set"].to_i.should == @number_of_memcache_set_calls.to_i
      end
    end
  end

end