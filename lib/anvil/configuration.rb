# frozen_string_literal: true

module Anvil
  class Configuration
    ENVIRONMENTS = %i[development production].freeze

    attr_accessor :api_key, :environment, :base_url, :graphql_url, :timeout, :open_timeout
    attr_writer :webhook_token

    def initialize
      @environment = default_environment
      @base_url = 'https://app.useanvil.com/api/v1'
      @graphql_url = 'https://app.useanvil.com/graphql' # GraphQL endpoint
      @timeout = 120         # Read timeout in seconds
      @open_timeout = 30     # Connection open timeout
      @api_key = ENV.fetch('ANVIL_API_KEY', nil)
      @webhook_token = ENV.fetch('ANVIL_WEBHOOK_TOKEN', nil)
    end

    def environment=(env)
      env = env.to_sym
      unless ENVIRONMENTS.include?(env)
        raise ArgumentError, "Invalid environment: #{env}. Must be one of: #{ENVIRONMENTS.join(', ')}"
      end

      @environment = env
    end

    def development?
      environment == :development
    end

    def production?
      environment == :production
    end

    def webhook_token
      @webhook_token || ENV.fetch('ANVIL_WEBHOOK_TOKEN', nil)
    end

    # Rate limits based on environment and plan
    def rate_limit
      return 4 if development?

      # Default production rate limit
      # Can be overridden if needed for custom plans
      4
    end

    def validate!
      return unless api_key.nil? || api_key.empty?

      raise Anvil::ConfigurationError, <<~ERROR
        No API key configured. Please set your API key using one of these methods:

        1. Rails initializer (config/initializers/anvil.rb):
           Anvil.configure do |config|
             config.api_key = Rails.application.credentials.anvil[:api_key]
           end

        2. Environment variable:
           export ANVIL_API_KEY="your_api_key_here"

        3. Direct assignment:
           Anvil.api_key = "your_api_key_here"

        Get your API keys at: https://app.useanvil.com/organizations/settings/api
      ERROR
    end

    private

    def default_environment
      # Check Rails environment if Rails is defined
      if defined?(Rails)
        Rails.env.production? ? :production : :development
      elsif ENV['ANVIL_ENV']
        ENV['ANVIL_ENV'].to_sym
      elsif ENV['RACK_ENV']
        ENV['RACK_ENV'] == 'production' ? :production : :development
      else
        :production
      end
    end
  end
end
