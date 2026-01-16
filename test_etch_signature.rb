#!/usr/bin/env ruby
# frozen_string_literal: true

# Create an Anvil Etch E-Signature Packet
# Using the correct GraphQL endpoint and mutation structure

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'
require 'net/http'
require 'uri'
require 'json'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

puts '=' * 50
puts '🖊️  Anvil Etch E-Signature Test'
puts '=' * 50

api_key = ENV.fetch('ANVIL_API_KEY', nil)
puts "\nUsing API Key: #{api_key[0..10]}..."

# Test 1: Basic GraphQL query to verify connection
def test_graphql_connection(api_key)
  puts "\n1️⃣  Testing GraphQL connection..."

  uri = URI('https://graphql.useanvil.com/')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path || '/')
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  query = {
    query: <<~GRAPHQL
      query {
        currentUser {
          eid
          name
        }
      }
    GRAPHQL
  }

  request.body = query.to_json
  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    if data['data']
      puts '   ✅ GraphQL connection works!'
      puts "   User: #{data['data']['currentUser']}"
      return true
    end
  end

  puts "   ❌ GraphQL connection failed: #{response.code}"
  puts "   Response: #{response.body[0..200]}"
  false
rescue StandardError => e
  puts "   ❌ Error: #{e.message}"
  false
end

# Test 2: Create a simple Etch packet (without a template for now)
def create_simple_etch_packet(api_key)
  puts "\n2️⃣  Creating a simple Etch packet..."

  uri = URI('https://graphql.useanvil.com/')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path || '/')
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  # Simple mutation - create a draft packet
  mutation = {
    query: <<~GRAPHQL
      mutation CreateTestPacket {
        createEtchPacket(
          name: "Test Signature Packet #{Time.now.to_i}"
          isDraft: true
          isTest: true
          signers: [
            {
              id: "signer1"
              name: "Test Signer"
              email: "test@example.com"
              signerType: "email"
            }
          ]
        ) {
          eid
          name
          status
          createdAt
        }
      }
    GRAPHQL
  }

  request.body = mutation.to_json
  response = http.request(request)
  result = JSON.parse(response.body)

  if response.code == '200'
    if result['data'] && result['data']['createEtchPacket']
      packet = result['data']['createEtchPacket']
      puts '   ✅ Etch packet created!'
      puts "   EID: #{packet['eid']}"
      puts "   Name: #{packet['name']}"
      puts "   Status: #{packet['status']}"
      return packet
    elsif result['errors']
      puts '   ❌ GraphQL errors:'
      result['errors'].each do |error|
        puts "      - #{error['message']}"
      end
    end
  else
    puts "   ❌ Request failed: #{response.code}"
    puts "   Response: #{result}"
  end

  nil
rescue StandardError => e
  puts "   ❌ Error: #{e.message}"
  nil
end

# Test 3: List existing Etch packets
def list_etch_packets(api_key)
  puts "\n3️⃣  Listing existing Etch packets..."

  uri = URI('https://graphql.useanvil.com/')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path || '/')
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  query = {
    query: <<~GRAPHQL
      query {
        etchPackets(limit: 5) {
          eid
          name
          status
          createdAt
        }
      }
    GRAPHQL
  }

  request.body = query.to_json
  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    if data['data'] && data['data']['etchPackets']
      packets = data['data']['etchPackets']
      if packets.empty?
        puts '   No Etch packets found'
      else
        puts "   Found #{packets.length} packet(s):"
        packets.each do |p|
          puts "   - #{p['name']} (#{p['status']})"
        end
      end
      return true
    end
  end

  puts '   ❌ Failed to list packets'
  false
rescue StandardError => e
  puts "   ❌ Error: #{e.message}"
  false
end

# Main execution
puts "\n🚀 Starting Etch e-signature tests..."

# Test GraphQL connection
if test_graphql_connection(api_key)
  # Try to list existing packets
  list_etch_packets(api_key)

  # Try to create a new packet
  packet = create_simple_etch_packet(api_key)

  if packet
    puts "\n#{'=' * 50}"
    puts '✅ Success!'
    puts '=' * 50
    puts "\nYou've successfully created an Etch signature packet!"
    puts "\nPacket ID: #{packet['eid']}"
    puts "Status: #{packet['status']}"

    puts "\n📚 Next steps:"
    puts '1. Add a PDF template or upload a document'
    puts '2. Configure signature fields'
    puts '3. Send to signers'
    puts '4. Track signature progress'

    puts "\n💡 To use with a PDF template:"
    puts '1. Upload a PDF template at https://app.useanvil.com'
    puts "2. Get the template's castEid"
    puts '3. Include it in the createEtchPacket mutation:'
    puts '   files: [{ id: "file1", castEid: "your_template_eid" }]'
  else
    puts "\n⚠️  Couldn't create a packet, but connection works!"
    puts "\nThis might be because:"
    puts '1. Your account might require a PDF file/template'
    puts '2. Additional fields might be required'
    puts '3. Check the Anvil dashboard for more details'
  end
else
  puts "\n❌ GraphQL connection failed"
  puts "\nPlease check:"
  puts '1. Your API key is correct'
  puts '2. Your account has API access enabled'
  puts '3. The GraphQL endpoint is accessible'
end

puts "\n📖 Documentation: https://www.useanvil.com/docs/api/e-signatures"
