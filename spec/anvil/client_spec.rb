# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Client do
  let(:api_key) { 'test_api_key_123' }
  let(:client) { described_class.new(api_key: api_key) }

  describe '#initialize' do
    it 'creates a client with an API key' do
      expect(client).to be_a(described_class)
      expect(client.config.api_key).to eq(api_key)
    end

    it 'uses default configuration when no config provided' do
      allow(ENV).to receive(:fetch).with('ANVIL_API_KEY', nil).and_return('env_key')
      allow(ENV).to receive(:fetch).with('ANVIL_WEBHOOK_TOKEN', nil).and_return(nil)

      # Reset configuration to pick up the new ENV mock
      Anvil.reset_configuration!

      client = described_class.new
      expect(client.config.api_key).to eq('env_key')
    end
  end

  describe '#query' do
    let(:graphql_query) do
      <<~GRAPHQL
        query GetCurrentUser {
          currentUser {
            eid
            name
            email
          }
        }
      GRAPHQL
    end

    let(:success_response) do
      {
        data: {
          currentUser: {
            eid: 'user123',
            name: 'John Doe',
            email: 'john@example.com'
          }
        }
      }
    end

    it 'executes a GraphQL query successfully' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .with(
          body: hash_including(query: graphql_query),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.query(query: graphql_query)

      expect(response).to be_a(Anvil::Response)
      expect(response.data[:currentUser][:eid]).to eq('user123')
    end

    it 'executes a GraphQL query with variables' do
      query_with_vars = <<~GRAPHQL
        query GetUser($eid: String!) {
          user(eid: $eid) {
            eid
            name
          }
        }
      GRAPHQL

      stub_request(:post, 'https://graphql.useanvil.com/')
        .with(
          body: hash_including(
            query: query_with_vars,
            variables: { eid: 'user123' }
          )
        )
        .to_return(
          status: 200,
          body: { data: { user: { eid: 'user123', name: 'John' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.query(
        query: query_with_vars,
        variables: { eid: 'user123' }
      )

      expect(response.data[:user][:name]).to eq('John')
    end

    it 'raises GraphQLError when query has errors' do
      error_response = {
        errors: [
          { message: 'Field not found' },
          { message: 'Invalid query syntax' }
        ]
      }

      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: error_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.query(query: graphql_query)
      end.to raise_error(Anvil::GraphQLError, /Field not found, Invalid query syntax/)
    end

    it 'allows custom GraphQL URL' do
      custom_url = 'https://custom.graphql.endpoint/'

      stub_request(:post, custom_url)
        .to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.query(
        query: graphql_query,
        graphql_url: custom_url
      )

      expect(response.data[:currentUser][:eid]).to eq('user123')
    end
  end

  describe '#mutation' do
    let(:graphql_mutation) do
      <<~GRAPHQL
        mutation UpdateUser($input: JSON) {
          updateUser(input: $input) {
            eid
            name
          }
        }
      GRAPHQL
    end

    let(:success_response) do
      {
        data: {
          updateUser: {
            eid: 'user123',
            name: 'Jane Doe'
          }
        }
      }
    end

    it 'executes a GraphQL mutation successfully' do
      stub_request(:post, 'https://graphql.useanvil.com/')
        .with(
          body: hash_including(
            query: graphql_mutation,
            variables: { input: { name: 'Jane Doe' } }
          )
        )
        .to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.mutation(
        mutation: graphql_mutation,
        variables: { input: { name: 'Jane Doe' } }
      )

      expect(response.data[:updateUser][:name]).to eq('Jane Doe')
    end

    it 'executes a mutation without variables' do
      simple_mutation = <<~GRAPHQL
        mutation {
          ping {
            message
          }
        }
      GRAPHQL

      stub_request(:post, 'https://graphql.useanvil.com/')
        .with(body: hash_including(query: simple_mutation))
        .to_return(
          status: 200,
          body: { data: { ping: { message: 'pong' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.mutation(mutation: simple_mutation)
      expect(response.data[:ping][:message]).to eq('pong')
    end

    it 'raises GraphQLError when mutation has errors' do
      error_response = {
        errors: [
          { message: 'Validation failed: Name is required' }
        ]
      }

      stub_request(:post, 'https://graphql.useanvil.com/')
        .to_return(
          status: 200,
          body: error_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.mutation(mutation: graphql_mutation, variables: {})
      end.to raise_error(Anvil::GraphQLError, /Validation failed/)
    end
  end
end
