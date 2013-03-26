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
    def self.query(sparql, accept_header, extra_params={})

      begin
        if defined?(Rails)
          Rails.logger.debug "TRIPOD: About to run query:"
          Rails.logger.debug sparql
        end

        params = {:query => sparql}.merge(extra_params)
        request_url = Tripod.query_endpoint + '?' + params.to_query
        streaming_opts = {:accept => accept_header, :timeout_seconds => Tripod.timeout_seconds}
        streaming_opts.merge!(:response_limit_bytes => Tripod.response_limit_bytes) if Tripod.response_limit_bytes

        # Hash.to_query from active support core extensions
        stream_data = -> {
          Tripod::Streaming.get_data(request_url, streaming_opts)
        }

        if Tripod.cache_store # if a cache store is configured
          # SHA-2 the key to keep the it within the small limit for many cache stores (e.g. Memcached is 250bytes)
          # Note: SHA2's are pretty certain to be unique http://en.wikipedia.org/wiki/SHA-2.
          key = 'SPARQL-QUERY-' + Digest::SHA2.hexdigest([extra_params, accept_header, sparql].join(" "))
          Tripod.cache_store.fetch(key, &stream_data)
        else
          stream_data.call()
        end

      rescue RestClient::BadRequest => e
        # just re-raise as a BadSparqlRequest Exception
        raise Tripod::Errors::BadSparqlRequest.new(e.http_body, e)
      end
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
      JSON.parse(query_response)["results"]["bindings"]
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
        RestClient::Request.execute(
          :method => :post,
          :url => Tripod.update_endpoint,
          :timeout => Tripod.timeout_seconds,
          :payload => {:update => sparql}
        )
        true
      rescue RestClient::BadRequest => e
        # just re-raise as a BadSparqlRequest Exception
        raise Tripod::Errors::BadSparqlRequest.new(e.http_body, e)
      end
    end

  end

  module Data
    class DataClient
      def self.submit(graph_uri, data, method)
        url = "#{Tripod.data_endpoint}?graph=#{graph_uri}"
        begin
          RestClient::Request.execute(
            :method => method,
            :url => url,
            :timeout => Tripod.timeout_seconds,
            :payload => data
          )
          true
        rescue RestClient::BadRequest => e
          raise Tripod::Errors::BadDataRequest.new(e.http_body, e)
        end
      end
    end

    def self.append(graph_uri, data)
      DataClient.submit(graph_uri, data, :post)
    end

    def self.replace(graph_uri, data)
      DataClient.submit(graph_uri, data, :put)
    end
  end
end