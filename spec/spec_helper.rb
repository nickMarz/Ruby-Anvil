# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'anvil'
require 'anvil/env_loader'

# Load .env file for tests
Anvil::EnvLoader.load(File.expand_path('../.env', __dir__))

# Only load VCR/WebMock if they're available (for full test suite)
begin
  require 'vcr'
  require 'webmock/rspec'
rescue LoadError
  # VCR and WebMock are optional for basic tests
end

# VCR configuration for recording API interactions (if available)
if defined?(VCR)
  VCR.configure do |config|
    config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    config.hook_into :webmock
    config.configure_rspec_metadata!

    # Filter sensitive data
    config.filter_sensitive_data('<API_KEY>') { ENV.fetch('ANVIL_API_KEY', nil) }
    config.filter_sensitive_data('<WEBHOOK_TOKEN>') { ENV.fetch('ANVIL_WEBHOOK_TOKEN', nil) }

    # Allow localhost for test servers
    config.ignore_localhost = true
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset Anvil configuration before each test
  config.before do
    # Mock environment variables to avoid configuration errors
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ANVIL_API_KEY', nil).and_return(nil)
    allow(ENV).to receive(:fetch).with('ANVIL_WEBHOOK_TOKEN', nil).and_return(nil)

    Anvil.reset_configuration!
  end

  # Configure test API key
  config.before(:each, :configured) do
    Anvil.configure do |anvil|
      anvil.api_key = ENV['ANVIL_API_KEY'] || 'test_api_key'
      anvil.environment = :development
    end
  end
end
