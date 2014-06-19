require 'dalli'
require 'connection_pool'

module Tripod
  module CacheStores

    # A Tripod::CacheStore that uses Memcached.
    # Note: Make sure you set the memcached -I (slab size) to big enough to store each result,
    # and set the -m (total size) to something quite big (or the cache will recycle too often).
    class MemcachedCacheStore

      # initialize a memcached cache store at the specified port (default 'localhost:11211')
      # a pool size should also be specified (defaults to 1 for development/local use reasons)
      def initialize(location, size = 1)
        @dalli_pool = ConnectionPool.new(:size => size, :timeout => 3) { Dalli::Client.new(location, :value_max_bytes => Tripod.response_limit_bytes) }
      end

      # takes a block
      def fetch(key)
        raise ArgumentError.new("expected a block") unless block_given?

        @dalli_pool.with do |client|
          client.fetch(key) { yield }
        end
      end

      def exist?(key)
        @dalli_pool.with do |client|
          !!client.get(key)
        end
      end

      def write(key, data)
        @dalli_pool.with do |client|
          client.set(key, data)
        end
      end

      def read(key)
        @dalli_pool.with do |client|
          client.get(key)
        end
      end

      def stats
        output = []
        @dalli_pool.with do |client|
          output << client.stats
        end
        output
      end

      def clear!
        @dalli_pool.with do |client|
          client.flush
        end
      end

    end
  end
end