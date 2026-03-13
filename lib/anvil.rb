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
      @default_client = nil
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

    # Execute a GraphQL query
    #
    # @param query [String] The GraphQL query string
    # @param variables [Hash] Variables to pass to the query
    # @return [Hash] The query result data
    def query(query:, variables: {})
      default_client.query(query: query, variables: variables)
    end

    # Execute a GraphQL mutation
    #
    # @param mutation [String] The GraphQL mutation string
    # @param variables [Hash] Variables to pass to the mutation
    # @return [Hash] The mutation result data
    def mutation(mutation:, variables: {})
      default_client.mutation(mutation: mutation, variables: variables)
    end

    private

    def default_client
      @default_client ||= Client.new
    end
  end
end

# Initialize with default configuration
Anvil.reset_configuration!
