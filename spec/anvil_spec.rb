# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil do
  it 'has a version number' do
    expect(Anvil::VERSION).not_to be_nil
    expect(Anvil::VERSION).to match(/^\d+\.\d+\.\d+/)
  end

  describe '.configure' do
    it 'yields configuration object' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Anvil::Configuration)
    end

    it 'sets API key through block' do
      described_class.configure do |config|
        config.api_key = 'test_key_123'
      end

      expect(described_class.api_key).to eq('test_key_123')
    end

    it 'sets environment through block' do
      described_class.configure do |config|
        config.environment = :development
      end

      expect(described_class.environment).to eq(:development)
      expect(described_class.development?).to be true
      expect(described_class.production?).to be false
    end
  end

  describe '.api_key=' do
    it 'sets the API key directly' do
      described_class.api_key = 'direct_key'
      expect(described_class.api_key).to eq('direct_key')
    end
  end

  describe '.api_key' do
    context 'when configured' do
      before do
        described_class.configure do |config|
          config.api_key = 'configured_key'
        end
      end

      it 'returns the configured key' do
        expect(described_class.api_key).to eq('configured_key')
      end
    end

    context 'when not configured but ENV variable exists' do
      before do
        allow(ENV).to receive(:fetch).with('ANVIL_API_KEY', nil).and_return('env_key')
        allow(ENV).to receive(:fetch).with('ANVIL_WEBHOOK_TOKEN', nil).and_return(nil)
        described_class.reset_configuration!
      end

      it 'returns the environment variable key' do
        expect(described_class.api_key).to eq('env_key')
      end
    end

    context 'when neither configured nor in ENV' do
      before do
        allow(ENV).to receive(:fetch).with('ANVIL_API_KEY', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('ANVIL_WEBHOOK_TOKEN', nil).and_return(nil)
        described_class.reset_configuration!
      end

      it 'returns nil' do
        expect(described_class.api_key).to be_nil
      end
    end
  end

  describe '.environment=' do
    it 'sets the environment' do
      described_class.environment = :production
      expect(described_class.environment).to eq(:production)
    end
  end

  describe '.development?' do
    it 'returns true when environment is development' do
      described_class.environment = :development
      expect(described_class.development?).to be true
    end

    it 'returns false when environment is production' do
      described_class.environment = :production
      expect(described_class.development?).to be false
    end
  end

  describe '.production?' do
    it 'returns true when environment is production' do
      described_class.environment = :production
      expect(described_class.production?).to be true
    end

    it 'returns false when environment is development' do
      described_class.environment = :development
      expect(described_class.production?).to be false
    end
  end

  describe '.reset_configuration!' do
    before do
      described_class.configure do |config|
        config.api_key = 'test_key'
        config.environment = :production
      end
    end

    it 'resets the configuration to defaults' do
      described_class.reset_configuration!

      # API key should be nil or from ENV
      expect(described_class.configuration.api_key).to eq(ENV.fetch('ANVIL_API_KEY', nil))

      # Environment should be back to default (depends on Rails/RACK_ENV/ANVIL_ENV)
      expect(described_class.configuration.environment).to(satisfy { |env| %i[development production].include?(env) })
    end
  end

  describe '.query', :configured do
    let(:graphql_query) do
      <<~GRAPHQL
        query GetCurrentUser {
          currentUser { eid name }
        }
      GRAPHQL
    end

    it 'executes a GraphQL query using the module' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: { data: { currentUser: { eid: 'u123', name: 'Test' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.query(query: graphql_query)
      expect(response.data[:currentUser][:eid]).to eq('u123')
    end

    it 'allows API key override' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: { data: { currentUser: { eid: 'u456', name: 'Override' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.query(
        query: graphql_query,
        api_key: 'override_key'
      )
      expect(response.data[:currentUser][:name]).to eq('Override')
    end
  end

  describe '.mutation', :configured do
    let(:graphql_mutation) do
      <<~GRAPHQL
        mutation CreateItem($input: JSON) {
          createItem(input: $input) { eid }
        }
      GRAPHQL
    end

    it 'executes a GraphQL mutation using the module' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: { data: { createItem: { eid: 'item123' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.mutation(
        mutation: graphql_mutation,
        variables: { input: { name: 'New Item' } }
      )
      expect(response.data[:createItem][:eid]).to eq('item123')
    end

    it 'allows API key override' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: { data: { createItem: { eid: 'item456' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.mutation(
        mutation: graphql_mutation,
        variables: { input: { name: 'Item' } },
        api_key: 'tenant_key'
      )
      expect(response.data[:createItem][:eid]).to eq('item456')
    end
  end
end
