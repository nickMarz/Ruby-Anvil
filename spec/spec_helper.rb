require 'bundler/setup'
require 'anvil'
require 'vcr'
require 'webmock/rspec'

# VCR configuration for recording API interactions
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV['ANVIL_API_KEY'] }
  config.filter_sensitive_data('<WEBHOOK_TOKEN>') { ENV['ANVIL_WEBHOOK_TOKEN'] }

  # Allow localhost for test servers
  config.ignore_localhost = true
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
  config.before(:each) do
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
