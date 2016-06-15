# encoding: utf-8

# this module is responsible for connecting to an http sparql endpoint
module Tripod::SparqlClient

  module Query

    # Runs a +sparql+ query against the endpoint. Returns a RestClient response object.
    #
    # @example Run a query
    #   Tripod::SparqlClient::Query.query('SELECT * WHERE {?s ?p ?o}')
    #
    # @param [ String ] sparql The sparql query.
    # @param [ String ] accept_header The accept header to send with the request
    # @param [ Hash ] any extra params to send with the request
    # @return [ RestClient::Response ]
    def self.query(sparql, accept_header, extra_params={}, response_limit_bytes = :default, extra_headers = {})

      non_sparql_params = (Tripod.extra_endpoint_params).merge(extra_params)
      params_hash = {:query => sparql}.merge(non_sparql_params)
      params = self.to_query(params_hash)
      request_url = Tripod.query_endpoint
      extra_headers.merge!(Tripod.extra_endpoint_headers)
      streaming_opts = {:accept => accept_header, :timeout_seconds => Tripod.timeout_seconds, :extra_headers => extra_headers}
      streaming_opts.merge!(_response_limit_options(response_limit_bytes)) if Tripod.response_limit_bytes

      # Hash.to_query from active support core extensions
      stream_data = -> {
        Tripod.logger.debug "TRIPOD: About to run query: #{sparql}"
        Tripod.logger.debug "TRIPOD: Streaming from url: #{request_url}"
        Tripod.logger.debug "TRIPOD: non sparql params #{non_sparql_params.to_s}"
        Tripod.logger.debug "TRIPOD: Streaming opts: #{streaming_opts.inspect}"
        Tripod::Streaming.get_data(request_url, params, streaming_opts)
      }

      if Tripod.cache_store # if a cache store is configured
        Tripod.logger.debug "TRIPOD: caching is on!"
        # SHA-2 the key to keep the it within the small limit for many cache stores (e.g. Memcached is 250bytes)
        # Note: SHA2's are pretty certain to be unique http://en.wikipedia.org/wiki/SHA-2.
        cache_key = 'SPARQL-QUERY-' + Digest::SHA2.hexdigest([extra_params, accept_header, sparql, Tripod.query_endpoint].join("-"))
        Tripod.cache_store.fetch(cache_key, &stream_data)
      else
        Tripod.logger.debug "TRIPOD caching is off!"
        stream_data.call()
      end

    end

    # Tripod helper to turn a hash to a query string, allowing multiple params in arrays
    # e.g. :query=>'foo', :graph=>['bar', 'baz']
    #  -> query=foo&graph=bar&graph=baz
    # based on the ActiveSupport implementation, but with different behaviour for arrays
    def self.to_query hash
      hash.collect_concat do |key, value|
        if value.class == Array
          value.collect { |v| v.to_query( key ) }
        else
          value.to_query(key)
        end
      end.sort * '&'
    end

    # Runs a SELECT +query+ against the endpoint. Returns a Hash of the results.
    #
    # @param [ String ] query The query to run
    #
    # @example Run a SELECT query
    #   Tripod::SparqlClient::Query.select('SELECT * WHERE {?s ?p ?o}')
    #
    # @return [ Hash, String ]
    def self.select(query)
      query_response = self.query(query, "application/sparql-results+json")
      if query_response.length >0 
        JSON.parse(query_response)["results"]["bindings"]
      else
        []
      end
    end

    def self._response_limit_options(response_limit_bytes)
      case response_limit_bytes
      when Integer
        {response_limit_bytes: response_limit_bytes}
      when :default
        {response_limit_bytes: Tripod.response_limit_bytes}
      when :no_response_limit
        {}
      end
    end
  end

  module Update

    # Runs a +sparql+ update against the endpoint. Returns true if success.
    #
    # @example Run a query
    #   Tripod::SparqlClient::Update.update('DELETE {?s ?p ?o} WHERE {?s ?p ?o};')
    #
    # @return [ true ]
    def self.update(sparql)
      begin
        headers = Tripod.extra_endpoint_headers.merge({:content_type => 'application/sparql-update'})
        RestClient::Request.execute(
          :method => :post,
          :url => Tripod.update_endpoint,
          :timeout => Tripod.timeout_seconds,
          :payload => { update: sparql }.merge(Tripod.extra_endpoint_params),
          :headers => headers
        )
        true
      rescue RestClient::BadRequest => e
        # just re-raise as a BadSparqlRequest Exception
        raise Tripod::Errors::BadSparqlRequest.new(e.http_body, e)
      end
    end

  end

end
