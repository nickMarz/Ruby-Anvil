# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Client, :configured do
  let(:client) { described_class.new(api_key: 'test_api_key') }
  let(:graphql_url) { 'https://graphql.useanvil.com/' }

  let(:http) { instance_double(Net::HTTP) }
  let(:http_response) { instance_double(Net::HTTPResponse) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(http_response)
    allow(http_response).to receive(:code).and_return('200')
    allow(http_response).to receive(:each_header)
  end

  describe '#graphql' do
    it 'sends a GraphQL request to the configured endpoint' do
      allow(http_response).to receive(:body).and_return(
        '{"data":{"currentUser":{"eid":"abc","name":"Test"}}}'
      )

      result = client.graphql(
        'query { currentUser { eid name } }'
      )

      expect(result).to eq({ currentUser: { eid: 'abc', name: 'Test' } })
    end

    it 'passes variables to the request' do
      allow(http_response).to receive(:body).and_return(
        '{"data":{"etchPacket":{"eid":"pkt_123","status":"draft"}}}'
      )

      result = client.graphql(
        'query GetPacket($eid: String!) { etchPacket(eid: $eid) { eid status } }',
        variables: { eid: 'pkt_123' }
      )

      expect(result).to eq({ etchPacket: { eid: 'pkt_123', status: 'draft' } })
    end

    it 'raises GraphQLError when response contains errors' do
      allow(http_response).to receive(:body).and_return(
        '{"errors":[{"message":"Not authorized"}],"data":null}'
      )

      expect do
        client.graphql('query { currentUser { eid } }')
      end.to raise_error(Anvil::GraphQLError, /Not authorized/)
    end

    it 'returns data when there are no errors' do
      allow(http_response).to receive(:body).and_return(
        '{"data":{"createWeld":{"eid":"weld_123","name":"My Workflow"}}}'
      )

      result = client.graphql(
        'mutation CreateWeld($input: JSON) { createWeld(variables: $input) { eid name } }',
        variables: { input: { name: 'My Workflow' } }
      )

      expect(result).to eq({ createWeld: { eid: 'weld_123', name: 'My Workflow' } })
    end
  end

  describe '#query' do
    it 'delegates to #graphql' do
      allow(http_response).to receive(:body).and_return(
        '{"data":{"currentUser":{"eid":"abc"}}}'
      )

      result = client.query(
        query: 'query { currentUser { eid } }',
        variables: {}
      )

      expect(result).to eq({ currentUser: { eid: 'abc' } })
    end
  end

  describe '#mutation' do
    it 'delegates to #graphql' do
      allow(http_response).to receive(:body).and_return(
        '{"data":{"createEtchPacket":{"eid":"pkt_123"}}}'
      )

      result = client.mutation(
        mutation: 'mutation { createEtchPacket { eid } }',
        variables: {}
      )

      expect(result).to eq({ createEtchPacket: { eid: 'pkt_123' } })
    end
  end
end

RSpec.describe Anvil, :configured do
  describe '.query' do
    let(:client) { instance_double(Anvil::Client) }

    before do
      described_class.instance_variable_set(:@default_client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
    end

    after do
      described_class.instance_variable_set(:@default_client, nil)
    end

    it 'delegates to default client' do
      expect(client).to receive(:query).with(
        query: 'query { currentUser { eid } }',
        variables: {}
      ).and_return({ currentUser: { eid: 'abc' } })

      result = described_class.query(query: 'query { currentUser { eid } }', variables: {})
      expect(result).to eq({ currentUser: { eid: 'abc' } })
    end
  end

  describe '.mutation' do
    let(:client) { instance_double(Anvil::Client) }

    before do
      described_class.instance_variable_set(:@default_client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
    end

    after do
      described_class.instance_variable_set(:@default_client, nil)
    end

    it 'delegates to default client' do
      expect(client).to receive(:mutation).with(
        mutation: 'mutation { createWeld { eid } }',
        variables: {}
      ).and_return({ createWeld: { eid: 'weld_123' } })

      result = described_class.mutation(mutation: 'mutation { createWeld { eid } }', variables: {})
      expect(result).to eq({ createWeld: { eid: 'weld_123' } })
    end
  end
end
