# frozen_string_literal: true

module Anvil
  # Base error class for all Anvil errors
  class Error < StandardError
    attr_reader :response, :code

    def initialize(message = nil, response = nil)
      @response = response
      @code = response&.code
      super(message || default_message)
    end

    private

    def default_message
      'An error occurred with the Anvil API'
    end
  end

  # Configuration errors
  class ConfigurationError < Error; end

  # API errors
  class APIError < Error
    attr_reader :status_code, :errors

    def initialize(message, response = nil)
      @status_code = response&.code&.to_i
      @errors = parse_errors(response) if response
      super
    end

    private

    def parse_errors(response)
      return [] unless response

      # Handle different response types
      body = if response.respond_to?(:body)
               response.body
             elsif response.is_a?(String)
               response
             else
               return []
             end

      return [] if body.nil? || body.empty?

      data = JSON.parse(body)
      data['errors'] || data['fields'] || []
    rescue JSON::ParserError
      []
    end
  end

  # Specific API error types
  class ValidationError < APIError; end
  class AuthenticationError < APIError; end

  class RateLimitError < APIError
    attr_reader :retry_after

    def initialize(message, response = nil)
      super
      @retry_after = response&.fetch('retry-after', nil)&.to_i if response
    end
  end

  class NotFoundError < APIError; end
  class ServerError < APIError; end

  # Network errors
  class NetworkError < Error; end
  class TimeoutError < NetworkError; end
  class ConnectionError < NetworkError; end

  # File errors
  class FileError < Error; end
  class FileNotFoundError < FileError; end
  class FileTooLargeError < FileError; end

  # Webhook errors
  class WebhookError < Error; end
  class WebhookVerificationError < WebhookError; end

  # GraphQL errors
  class GraphQLError < APIError; end
end
