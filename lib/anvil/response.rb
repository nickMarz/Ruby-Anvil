# frozen_string_literal: true

module Anvil
  class Response
    attr_reader :http_response, :raw_body, :code, :headers

    def initialize(http_response)
      @http_response = http_response
      @code = http_response.code.to_i
      @raw_body = http_response.body
      @headers = extract_headers(http_response)
    end

    def success?
      code >= 200 && code < 300
    end

    def error?
      !success?
    end

    def body
      return raw_body if binary?

      @body ||= begin
        JSON.parse(raw_body, symbolize_names: true)
      rescue JSON::ParserError
        raw_body
      end
    end

    def data
      return raw_body if binary?

      if body.is_a?(Hash)
        body[:data] || body
      else
        body
      end
    end

    def errors
      return [] unless error? && body.is_a?(Hash)

      body[:errors] || body[:fields] || []
    end

    def error_message
      return nil unless error?

      if errors.any?
        errors.map { |e| e[:message] || e['message'] }.join(', ')
      elsif body.is_a?(Hash) && body[:message]
        body[:message]
      else
        "HTTP #{code} Error"
      end
    end

    # Rate limiting headers
    def rate_limit
      headers['x-ratelimit-limit']&.to_i
    end

    def rate_limit_remaining
      headers['x-ratelimit-remaining']&.to_i
    end

    def rate_limit_reset
      reset = headers['x-ratelimit-reset']&.to_i
      Time.at(reset) if reset
    end

    def retry_after
      headers['retry-after']&.to_i
    end

    def binary?
      content_type = headers['content-type'] || ''
      content_type.include?('application/pdf') ||
        content_type.include?('application/octet-stream') ||
        content_type.include?('application/zip')
    end

    private

    def extract_headers(response)
      headers = {}
      response.each_header do |key, value|
        headers[key.downcase] = value
      end
      headers
    end
  end
end
