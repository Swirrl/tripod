# encoding: utf-8

# this module is responsible for connecting to an http sparql endpoint
module Tripod::SparqlClient

  module Query

    # Runs a +sparql+ query against the endpoint. Returns a RestClient response object.
    #
    # @example Run a query
    #   Tripod::SparqlClient::Query.query('SELECT * WHERE {?s ?p ?o}')
    #
    # @return [ RestClient::Response ]
    def self.query(sparql, format='json', headers = {})

      begin
        params = { :params => {:query => sparql, :output => format } }
        hdrs = headers.merge(params)
        RestClient::Request.execute(
          :method => :get,
          :url => Tripod.query_endpoint,
          :headers => hdrs,
          :timeout => Tripod.timeout_seconds,
        )
      rescue RestClient::BadRequest => e
        body = e.http_body
        if body.start_with?('Error 400: Parse error:')
          # TODO: this is a SPARQL parsing exception. Do something different.
          raise e
        else
          raise e
        end
      end
    end

    # Runs a SELECT +query+ against the endpoint. Returns a hash of the results.
    # Specify +raw_format+ if you want the results raw, as returned from the SPARQL endpoint.
    #
    # @param [ String ] query The query to run
    # @param [ String ] raw_format valid formats are: 'json', 'text', 'csv', 'xml'
    #
    # @example Run a SELECT query
    #   Tripod::SparqlClient::Query.select('SELECT * WHERE {?s ?p ?o}')
    #
    # @return [ Hash, String ]
    def self.select(query, raw_format=nil)
      query_response = self.query(query, (raw_format || 'json'))
      if raw_format
        query_response.body
      else
        JSON.parse(query_response.body)["results"]["bindings"]
      end
    end

    # Executes a DESCRIBE +query+ against the SPARQL endpoint.
    # Executes the +query+ and returns ntriples by default
    #
    # @example Run a DESCRIBE query
    #   Tripod::SparqlClient::Query.select('DESCRIBE <http://foo>')
    #
    # @param [ String ] query The query to run
    # @param [ String ] accept_header The header to pass to the database.
    # 
    # @return [ String ] the raw response from the endpoint
    def self.describe(query, accept_header='application/n-triples')
      response = self.query(query, nil, {:accept=>accept_header})
      return response.body
    end

    # Executes an ASK +query+ against the SPARQL endpoint.
    # Executes the +query+ and returns text by default
    #
    # @example Run a ASK query
    #   Tripod::SparqlClient::Query.select('ASK <http://foo>')
    #
    # @param [ String ] query The query to run
    # @param [ String ] accept_header The format parameter to send to the database. Valud valid formats are text, xml, json
    # 
    # @return [ String ] the raw response from the endpoint
    def self.ask(query, format='text')
      response = self.query(query, format)
      return response.body
    end

    # Executes a CONSTRUCT +query+ against the SPARQL endpoint.
    # Executes the +query+ and returns ntriples by default
    #
    # @example Run a CONSTRUCT query
    #   Tripod::SparqlClient::Query.select('CONSTRUCT <http://foo>')
    #
    # @param [ String ] query The query to run
    # @param [ String ] accept_header The header to pass to the database.
    # 
    # @return [ String ] the raw response from the endpoint
    def self.construct(query, accept_header='application/n-triples')
      response = self.query(query, nil, {:accept=>accept_header})
      return response.body
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
        body = e.http_body
        if body.start_with?('Error 400: Parse error:')
          # TODO: this is a SPARQL parsing exception. Do something different.
          raise e
        else
          raise e
        end
      end
    end

  end
end