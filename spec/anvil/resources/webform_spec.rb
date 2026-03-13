# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Webform, :configured do
  let(:client) { instance_double(Anvil::Client, config: Anvil.configuration) }
  let(:form_attrs) do
    {
      eid: 'frg_123',
      name: 'Contact Form',
      slug: 'contact-form',
      fields: [
        { type: 'text', name: 'full_name', label: 'Full Name' },
        { type: 'email', name: 'email', label: 'Email' }
      ]
    }
  end
  let(:form) { described_class.new(form_attrs, client: client) }

  before do
    described_class.instance_variable_set(:@client, nil)
    allow(Anvil::Client).to receive(:new).and_return(client)
  end

  after do
    described_class.instance_variable_set(:@client, nil)
  end

  describe '.create' do
    it 'creates a new webform' do
      expect(client).to receive(:graphql).and_return({ createForge: form_attrs })

      result = described_class.create(
        name: 'Contact Form',
        fields: form_attrs[:fields]
      )
      expect(result).to be_a(described_class)
      expect(result.name).to eq('Contact Form')
      expect(result.eid).to eq('frg_123')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect do
        described_class.create(name: 'Test', fields: [])
      end.to raise_error(Anvil::APIError, /Failed to create webform/)
    end
  end

  describe '.find' do
    it 'finds a webform by EID' do
      expect(client).to receive(:graphql).and_return({ forge: form_attrs })

      result = described_class.find('frg_123', client: client)
      expect(result).to be_a(described_class)
      expect(result.name).to eq('Contact Form')
    end

    it 'raises NotFoundError when not found' do
      expect(client).to receive(:graphql).and_return(nil)

      expect do
        described_class.find('frg_bad', client: client)
      end.to raise_error(Anvil::NotFoundError, /Webform not found/)
    end
  end

  describe '#submit' do
    it 'submits form data' do
      expect(client).to receive(:graphql).and_return({
        createSubmission: { eid: 'sub_123', data: { full_name: 'John' }, createdAt: '2024-01-01' }
      })

      result = form.submit(data: { full_name: 'John', email: 'john@example.com' })
      expect(result[:eid]).to eq('sub_123')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { form.submit(data: {}) }.to raise_error(Anvil::APIError, /Failed to submit form data/)
    end
  end

  describe '#submissions' do
    it 'returns form submissions' do
      expect(client).to receive(:graphql).and_return({
        forgeSubmissions: [
          { eid: 'sub_1', data: { full_name: 'John' } },
          { eid: 'sub_2', data: { full_name: 'Jane' } }
        ]
      })

      results = form.submissions
      expect(results.length).to eq(2)
    end

    it 'returns empty array when no submissions' do
      expect(client).to receive(:graphql).and_return(nil)

      expect(form.submissions).to eq([])
    end

    it 'supports pagination' do
      expect(client).to receive(:graphql).with(
        anything,
        variables: hash_including(limit: 5, offset: 10)
      ).and_return({ forgeSubmissions: [] })

      form.submissions(limit: 5, offset: 10)
    end
  end

  describe '#fields' do
    it 'returns form fields' do
      expect(form.fields.length).to eq(2)
      expect(form.fields.first[:name]).to eq('full_name')
    end

    it 'returns empty array when no fields' do
      empty_form = described_class.new({ eid: 'frg_empty' }, client: client)
      expect(empty_form.fields).to eq([])
    end
  end
end
