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
  end
end

# Initialize with default configuration
Anvil.reset_configuration!
