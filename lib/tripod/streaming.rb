# -*- coding: utf-8 -*-
require 'net/http'

module Tripod
  module Streaming

    def self.create_http_client(uri, opts)
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = uri.scheme == 'https'
      client.read_timeout = opts[:timeout_seconds] || 10
      client
    end

    def self.create_request(uri, opts)
      headers = opts[:extra_headers] || {}
      a = opts[:accept] || headers['Accept'] || '*/*'
      headers['Accept'] = a

      req = Net::HTTP::Post.new(uri.request_uri, headers)

      if uri.user
        req.basic_auth(uri.user, uri.password)
      end
      req
    end

    # stream data from a url
    # opts
    #  :accept => "*/*"
    #  :timeout_seconds = 10
    #  :response_limit_bytes = nil
    def self.get_data(request_url, payload, opts={})
      limit_in_bytes = opts[:response_limit_bytes]
      uri = URI(request_url)

      http = self.create_http_client(uri, opts)
      post_request = self.create_request(uri, opts)

      total_bytes = 0

      request_start_time = Time.now if Tripod.logger.debug?

      response = StringIO.new

      begin
        http.request(post_request, payload) do |res|

          response_duration = Time.now - request_start_time if Tripod.logger.debug?

          Tripod.logger.debug "TRIPOD: received response code: #{res.code} in: #{response_duration} secs"

          if res.code.to_i == 503
            raise Tripod::Errors::Timeout.new
          elsif res.code.to_s != "200"
            raise Tripod::Errors::BadSparqlRequest.new(res.body)
          end

          stream_start_time = Time.now if Tripod.logger.debug?

          response.set_encoding('UTF-8')
          res.read_body do |seg|
            total_bytes += seg.bytesize
            raise Tripod::Errors::SparqlResponseTooLarge.new if limit_in_bytes && (total_bytes > limit_in_bytes)
            response << seg
            seg
          end

          if Tripod.logger.debug?
            stream_duration = Time.now - stream_start_time
            total_request_time = Time.now - request_start_time
          end

          if Tripod.logger.debug?
            Tripod.logger.debug "TRIPOD: #{total_bytes} bytes streamed in: #{stream_duration} secs"          
            time_str = "TRIPOD: total request time: #{total_request_time} secs" 
            time_str += "!!! SLOW !!! " if total_request_time >= 1.0
            Tripod.logger.debug time_str
          end
          
        end
      rescue Timeout::Error => timeout
        raise Tripod::Errors::Timeout.new
      end

      response.string
    end

  end
end
