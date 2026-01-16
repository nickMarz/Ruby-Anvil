# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'
require 'uri'
require 'date'

require_relative 'anvil/version'
require_relative 'anvil/configuration'
require_relative 'anvil/errors'
require_relative 'anvil/response'
require_relative 'anvil/client'
require_relative 'anvil/rate_limiter'
require_relative 'anvil/resources/base'
require_relative 'anvil/resources/pdf'
require_relative 'anvil/resources/signature'
require_relative 'anvil/resources/webhook'

module Anvil
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    def reset_configuration!
      self.configuration = Configuration.new
    end

    # Convenience methods for quick configuration
    def api_key=(key)
      configure { |config| config.api_key = key }
    end

    def api_key
      configuration&.api_key || ENV.fetch('ANVIL_API_KEY', nil)
    end

    def environment=(env)
      configure { |config| config.environment = env }
    end

    def environment
      configuration&.environment || :production
    end

    def development?
      environment == :development
    end

    def production?
      environment == :production
    end

    # Execute a GraphQL query using the default or configured API key
    #
    # @param query [String] The GraphQL query string
    # @param variables [Hash] Variables for the query (optional)
    # @param options [Hash] Additional options (including :api_key for override)
    # @return [Response] The API response containing query results
    #
    # @example
    #   result = Anvil.query(
    #     query: 'query GetUser { currentUser { eid name } }',
    #     variables: {}
    #   )
    def query(query:, variables: {}, **options)
      api_key = options.delete(:api_key)
      client = api_key ? Client.new(api_key: api_key) : Client.new
      client.query(query: query, variables: variables, **options)
    end

    # Execute a GraphQL mutation using the default or configured API key
    #
    # @param mutation [String] The GraphQL mutation string
    # @param variables [Hash] Variables for the mutation (optional)
    # @param options [Hash] Additional options (including :api_key for override)
    # @return [Response] The API response containing mutation results
    #
    # @example
    #   result = Anvil.mutation(
    #     mutation: 'mutation CreateCast($input: JSON) { createCast(input: $input) { eid } }',
    #     variables: { input: { name: "Template" } }
    #   )
    def mutation(mutation:, variables: {}, **options)
      api_key = options.delete(:api_key)
      client = api_key ? Client.new(api_key: api_key) : Client.new
      client.mutation(mutation: mutation, variables: variables, **options)
    end
  end
end

# Initialize with default configuration
Anvil.reset_configuration!
