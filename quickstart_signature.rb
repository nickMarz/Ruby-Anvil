#!/usr/bin/env ruby
# frozen_string_literal: true

# Anvil E-Signature Quickstart
# Based on: https://www.useanvil.com/docs/api/e-signatures

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

# Configure Anvil
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.environment = :development
end

puts "=" * 50
puts "Anvil E-Signature Quickstart"
puts "=" * 50
puts "\nUsing API Key: #{ENV['ANVIL_API_KEY'][0..10]}..."

# Since the Signature class uses GraphQL, we need to test it differently
# Let's create a test packet using the REST API directly

def create_test_etch_packet
  puts "\n📝 Creating a test e-signature packet..."

  client = Anvil::Client.new

  # GraphQL mutation for creating an Etch packet
  # Note: This creates a simple test packet without files
  mutation = <<~GRAPHQL
    mutation CreateEtchPacket {
      createEtchPacket(
        name: "Test Agreement - Ruby Gem #{Time.now.to_i}",
        isDraft: false,
        signers: [
          {
            name: "Test Signer 1",
            email: "test1@example.com",
            signerType: "email"
          }
        ]
      ) {
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

  begin
    response = client.post('https://app.useanvil.com/graphql', {
      query: mutation
    })

    if response.success?
      data = response.data
      if data[:data] && data[:data][:createEtchPacket]
        packet = data[:data][:createEtchPacket]

        puts "✅ Signature packet created successfully!"
        puts "\n📋 Packet Details:"
        puts "   EID: #{packet[:eid]}"
        puts "   Name: #{packet[:name]}"
        puts "   Status: #{packet[:status]}"
        puts "   Created: #{packet[:createdAt]}"

        if packet[:signers]
          puts "\n👥 Signers:"
          packet[:signers].each do |signer|
            puts "   - #{signer[:name]} (#{signer[:email]})"
            puts "     Status: #{signer[:status]}"
            puts "     EID: #{signer[:eid]}"
          end
        end

        # Get signing URL
        generate_signing_url(packet[:eid], packet[:signers].first[:eid])

        packet
      else
        puts "❌ No packet data returned"
        puts "Response: #{data.inspect}"
      end
    else
      puts "❌ Request failed: #{response.error_message}"
    end

  rescue => e
    puts "❌ Error: #{e.message}"
    puts e.backtrace.first(5)
  end
end

def generate_signing_url(packet_eid, signer_eid)
  puts "\n🔗 Generating signing URL..."

  client = Anvil::Client.new

  mutation = <<~GRAPHQL
    mutation GenerateEtchSignURL {
      generateEtchSignURL(
        input: {
          packetEid: "#{packet_eid}"
          signerEid: "#{signer_eid}"
        }
      ) {
        url
      }
    }
  GRAPHQL

  begin
    response = client.post('https://app.useanvil.com/graphql', {
      query: mutation
    })

    if response.success?
      data = response.data
      if data[:data] && data[:data][:generateEtchSignURL]
        url = data[:data][:generateEtchSignURL][:url]
        puts "✅ Signing URL generated:"
        puts "   #{url}"
        puts "\n📧 Send this URL to the signer to collect their signature"
        url
      else
        puts "❌ No URL returned"
      end
    else
      puts "❌ Failed to generate URL: #{response.error_message}"
    end
  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

def list_etch_packets
  puts "\n📑 Listing your signature packets..."

  client = Anvil::Client.new

  query = <<~GRAPHQL
    query ListEtchPackets {
      etchPackets(limit: 5) {
        eid
        name
        status
        createdAt
        completedAt
      }
    }
  GRAPHQL

  begin
    response = client.post('https://app.useanvil.com/graphql', {
      query: query
    })

    if response.success?
      data = response.data
      if data[:data] && data[:data][:etchPackets]
        packets = data[:data][:etchPackets]

        if packets.empty?
          puts "No signature packets found"
        else
          puts "Found #{packets.length} packet(s):"
          packets.each do |packet|
            puts "\n   📋 #{packet[:name]}"
            puts "      EID: #{packet[:eid]}"
            puts "      Status: #{packet[:status]}"
            puts "      Created: #{packet[:createdAt]}"
            puts "      Completed: #{packet[:completedAt] || 'Not yet'}"
          end
        end
      end
    else
      puts "❌ Failed to list packets: #{response.error_message}"
    end
  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

# Main execution
puts "\n🚀 Testing Anvil E-Signature API..."

# List existing packets
list_etch_packets

# Create a new test packet
packet = create_test_etch_packet

puts "\n" + "=" * 50
puts "✅ E-Signature API test complete!"
puts "=" * 50

puts "\n📚 What just happened:"
puts "1. Created a signature packet with the Anvil API"
puts "2. Added a test signer"
puts "3. Generated a signing URL"

puts "\n💡 Next steps:"
puts "1. The signer would receive the URL via email (in production)"
puts "2. They click the link and sign the document"
puts "3. You receive a webhook when complete"
puts "4. You can download the signed document"

puts "\n📖 Learn more:"
puts "   https://www.useanvil.com/docs/api/e-signatures"