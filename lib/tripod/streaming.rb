# -*- coding: utf-8 -*-
require 'net/http'

module Tripod
  module Streaming

    # stream data from a url
    # opts
    #  :accept => "*/*"
    #  :timeout_seconds = 10
    #  :response_limit_bytes = nil
    def self.get_data(request_url, payload, opts={})

      accept = opts[:accept] || "*/*"
      timeout_in_seconds = opts[:timeout_seconds] || 10
      limit_in_bytes = opts[:response_limit_bytes]

      uri = URI(request_url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = timeout_in_seconds

      total_bytes = 0

      request_start_time = Time.now if Tripod.logger.debug?

      response = StringIO.new

      begin
        http.request_post(uri.request_uri, payload, 'Accept' => accept) do |res|

          response_duration = Time.now - request_start_time if Tripod.logger.debug?

          Tripod.logger.debug "TRIPOD: received response code: #{res.code} in: #{response_duration} secs"
          raise Tripod::Errors::BadSparqlRequest.new(res.body) if res.code.to_s != "200"

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

          Tripod.logger.debug "TRIPOD: #{total_bytes} bytes streamed in: #{stream_duration} secs"
          Tripod.logger.debug "TRIPOD: total request time: #{total_request_time} secs"
        end
      rescue Timeout::Error => timeout
        raise Tripod::Errors::Timeout.new
      end

      response.string
    end

  end
end
