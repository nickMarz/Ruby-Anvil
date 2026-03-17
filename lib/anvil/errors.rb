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
      data = extract_response_data(response)
      return [] unless data

      data[:errors] || data['errors'] || data[:fields] || data['fields'] || []
    rescue JSON::ParserError
      []
    end

    def extract_response_data(response)
      return nil unless response

      body = response.respond_to?(:body) ? response.body : response
      return nil unless body.is_a?(String) || body.is_a?(Hash)
      return nil if body.respond_to?(:empty?) && body.empty?

      body.is_a?(Hash) ? body : JSON.parse(body)
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

  # GraphQL errors
  class GraphQLError < APIError
    attr_reader :graphql_errors

    def initialize(message, response = nil, graphql_errors: [])
      @graphql_errors = graphql_errors
      super(message, response)
    end
  end

  # Webhook errors
  class WebhookError < Error; end
  class WebhookVerificationError < WebhookError; end
end
