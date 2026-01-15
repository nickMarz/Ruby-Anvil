# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Configuration do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.environment).to eq(:production)
      expect(config.base_url).to eq('https://app.useanvil.com/api/v1')
      expect(config.timeout).to eq(120)
      expect(config.open_timeout).to eq(30)
    end

    it 'reads API key from environment' do
      allow(ENV).to receive(:[]).with('ANVIL_API_KEY').and_return('env_api_key')
      config = described_class.new
      expect(config.api_key).to eq('env_api_key')
    end

    it 'reads webhook token from environment' do
      allow(ENV).to receive(:[]).with('ANVIL_API_KEY').and_return(nil)
      allow(ENV).to receive(:[]).with('ANVIL_WEBHOOK_TOKEN').and_return('env_webhook_token')
      config = described_class.new
      expect(config.webhook_token).to eq('env_webhook_token')
    end
  end

  describe '#environment=' do
    it 'accepts valid environments' do
      config.environment = :development
      expect(config.environment).to eq(:development)

      config.environment = :production
      expect(config.environment).to eq(:production)
    end

    it 'raises error for invalid environment' do
      expect { config.environment = :staging }.to raise_error(ArgumentError, /Invalid environment/)
    end

    it 'converts strings to symbols' do
      config.environment = 'development'
      expect(config.environment).to eq(:development)
    end
  end

  describe '#development?' do
    it 'returns true when environment is development' do
      config.environment = :development
      expect(config.development?).to be true
    end

    it 'returns false when environment is production' do
      config.environment = :production
      expect(config.development?).to be false
    end
  end

  describe '#production?' do
    it 'returns true when environment is production' do
      config.environment = :production
      expect(config.production?).to be true
    end

    it 'returns false when environment is development' do
      config.environment = :development
      expect(config.production?).to be false
    end
  end

  describe '#rate_limit' do
    it 'returns 4 for development environment' do
      config.environment = :development
      expect(config.rate_limit).to eq(4)
    end

    it 'returns 4 for production environment by default' do
      config.environment = :production
      expect(config.rate_limit).to eq(4)
    end
  end

  describe '#validate!' do
    context 'with valid API key' do
      before { config.api_key = 'valid_key' }

      it 'does not raise error' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'without API key' do
      before { config.api_key = nil }

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(Anvil::ConfigurationError, /No API key configured/)
      end
    end

    context 'with empty API key' do
      before { config.api_key = '' }

      it 'raises ConfigurationError' do
        expect { config.validate! }.to raise_error(Anvil::ConfigurationError, /No API key configured/)
      end
    end
  end

  describe 'webhook_token' do
    it 'returns set token over environment variable' do
      allow(ENV).to receive(:[]).with('ANVIL_WEBHOOK_TOKEN').and_return('env_token')
      config.webhook_token = 'set_token'
      expect(config.webhook_token).to eq('set_token')
    end

    it 'returns environment token when not set' do
      allow(ENV).to receive(:[]).with('ANVIL_API_KEY').and_return(nil)
      allow(ENV).to receive(:[]).with('ANVIL_WEBHOOK_TOKEN').and_return('env_token')
      config = described_class.new
      expect(config.webhook_token).to eq('env_token')
    end
  end
end