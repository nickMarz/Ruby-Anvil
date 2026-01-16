#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating generic GraphQL support in Anvil Ruby gem
#
# This example shows how to use the generic query and mutation methods
# to interact with any part of the Anvil GraphQL API, even features
# not yet wrapped by the gem.

require 'bundler/setup'
require 'anvil'
require 'anvil/env_loader'

# Load environment variables
Anvil::EnvLoader.load

# Configure Anvil
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.environment = :development
end

puts "=" * 60
puts "Anvil Generic GraphQL Support Examples"
puts "=" * 60
puts

# Example 1: Query current user information
puts "1. Get current user information"
puts "-" * 60

begin
  response = Anvil.query(
    query: <<~GRAPHQL
      query GetCurrentUser {
        currentUser {
          eid
          name
          email
        }
      }
    GRAPHQL
  )

  user = response.data[:data][:currentUser]
  puts "User ID: #{user[:eid]}"
  puts "Name: #{user[:name]}"
  puts "Email: #{user[:email]}"
rescue Anvil::GraphQLError => e
  puts "GraphQL Error: #{e.message}"
rescue Anvil::Error => e
  puts "Error: #{e.message}"
end

puts
puts "=" * 60
puts

# Example 2: Query with variables
puts "2. Query etch packet with variables"
puts "-" * 60

begin
  # You can pass variables to your queries
  response = Anvil.query(
    query: <<~GRAPHQL,
      query GetEtchPacket($eid: String!) {
        etchPacket(eid: $eid) {
          eid
          name
          status
          createdAt
          signers {
            eid
            name
            email
            status
          }
        }
      }
    GRAPHQL
    variables: {
      eid: ENV['ANVIL_PACKET_EID'] || 'your_packet_eid_here'
    }
  )

  packet = response.data[:data][:etchPacket]
  if packet
    puts "Packet: #{packet[:name]}"
    puts "Status: #{packet[:status]}"
    puts "Created: #{packet[:createdAt]}"
    puts "Signers: #{packet[:signers]&.length || 0}"
  else
    puts "Packet not found (update ANVIL_PACKET_EID in .env)"
  end
rescue Anvil::GraphQLError => e
  puts "GraphQL Error: #{e.message}"
rescue Anvil::Error => e
  puts "Error: #{e.message}"
end

puts
puts "=" * 60
puts

# Example 3: Create mutation (example with a hypothetical Cast creation)
puts "3. Execute a mutation (example structure)"
puts "-" * 60

puts <<~INFO
  # Example mutation structure (not executed):
  
  response = Anvil.mutation(
    mutation: <<~GRAPHQL,
      mutation CreateCast($input: JSON) {
        createCast(input: $input) {
          eid
          name
          createdAt
        }
      }
    GRAPHQL
    variables: {
      input: {
        name: "My Template",
        file: "base64_encoded_pdf_here"
      }
    }
  )
  
  cast = response.data[:data][:createCast]
  puts "Created cast: \#{cast[:eid]}"
INFO

puts
puts "=" * 60
puts

# Example 4: Using client instance for multi-tenancy
puts "4. Multi-tenant usage with custom API key"
puts "-" * 60

puts <<~INFO
  # For multi-tenant applications, you can use different API keys:
  
  tenant_client = Anvil::Client.new(api_key: tenant.anvil_api_key)
  response = tenant_client.query(
    query: 'query { currentUser { name } }'
  )
  
  # Or use the module-level methods with api_key parameter:
  response = Anvil.query(
    query: 'query { currentUser { name } }',
    api_key: tenant.anvil_api_key
  )
INFO

puts
puts "=" * 60
puts

# Example 5: Error handling
puts "5. Error handling example"
puts "-" * 60

puts <<~INFO
  # GraphQL errors are raised as Anvil::GraphQLError:
  
  begin
    response = Anvil.query(
      query: 'query { invalidField { data } }'
    )
  rescue Anvil::GraphQLError => e
    puts "GraphQL error occurred: \#{e.message}"
    puts "Status code: \#{e.status_code}"
  rescue Anvil::AuthenticationError => e
    puts "Authentication failed: \#{e.message}"
  rescue Anvil::Error => e
    puts "General error: \#{e.message}"
  end
INFO

puts
puts "=" * 60
puts "Complete! Generic GraphQL support allows you to access"
puts "any part of the Anvil API, even features not yet wrapped"
puts "by dedicated Ruby methods."
puts "=" * 60
