require 'dalli'

module Tripod
  module CacheStores

    # A Tripod::CacheStore that uses Memcached.
    # Note: Make sure you set the memcached -I (slab size) to big enough to store each result,
    # and set the -m (total size) to something quite big (or the cache will recycle too often).
    class MemcachedCacheStore

      # initialize a memcached cache store at the specified port (default 'localhost:11211')
      def initialize(location)
        @dalli = Dalli::Client.new(location, :value_max_bytes => Tripod.response_limit_bytes)
      end

      # takes a block
      def fetch(key)
        raise ArgumentError.new("expected a block") unless block_given?

        @dalli.fetch(key) do
          yield
        end
      end

      def exist?(key)
        !!@dalli.get(key)
      end

      def write(key, data)
        @dalli.set(key, data)
      end

      def read(key)
        @dalli.get(key)
      end

      def clear!
        @dalli.flush
      end

    end
  end
end