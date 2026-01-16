#!/usr/bin/env ruby
# frozen_string_literal: true

# Create an Anvil E-Signature Packet
# Based on the official Anvil API documentation

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'
require 'net/http'
require 'uri'
require 'json'
require 'base64'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

puts '=' * 50
puts 'Anvil E-Signature Packet Creation'
puts '=' * 50

api_key = ENV.fetch('ANVIL_API_KEY', nil)
puts "\nUsing API Key: #{api_key[0..10]}..."

# Step 1: Create a simple PDF to use for signing
def create_test_pdf(api_key)
  puts "\n📄 Creating a test PDF document..."

  uri = URI('https://app.useanvil.com/api/v1/generate-pdf')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  html = <<~HTML
    <!DOCTYPE html>
    <html>
    <body style="padding: 40px; font-family: Arial;">
      <h1>Test Agreement</h1>
      <p>This is a test document for e-signature.</p>

      <p>I, the undersigned, agree to the terms of this test agreement.</p>

      <div style="margin-top: 100px; border-top: 2px solid black; width: 300px; padding-top: 10px;">
        Signature
      </div>

      <div style="margin-top: 50px; border-top: 2px solid black; width: 300px; padding-top: 10px;">
        Date
      </div>
    </body>
    </html>
  HTML

  request.body = {
    type: 'html',
    data: {
      html: html,
      css: 'body { font-size: 14px; }'
    }
  }.to_json

  response = http.request(request)

  if response.code == '200'
    puts '   ✅ PDF created successfully'
    response.body # Return the PDF binary data
  else
    puts "   ❌ Failed to create PDF: #{response.code}"
    nil
  end
end

# Step 2: Create an e-signature packet using REST API (simpler than GraphQL)
def create_etch_packet_rest(api_key, _pdf_data = nil)
  puts "\n📝 Creating e-signature packet via REST API..."

  # For now, create a simple packet without a file
  # In production, you'd upload the PDF or use a template

  uri = URI('https://app.useanvil.com/api/v1/etch-packets')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  # Basic packet structure
  packet_data = {
    name: "Test Agreement #{Time.now.strftime('%Y-%m-%d %H:%M')}",
    isDraft: false,
    isTest: true, # Test mode - won't send real emails
    signers: [
      {
        id: 'signer1',
        name: 'Test User',
        email: 'test@example.com',
        signerType: 'email'
      }
    ]
  }

  request.body = packet_data.to_json

  response = http.request(request)
  result = begin
    JSON.parse(response.body)
  rescue StandardError
    response.body
  end

  if %w[200 201].include?(response.code)
    puts '   ✅ Packet created successfully!'
    if result.is_a?(Hash)
      puts "   Packet ID: #{result['eid'] || result['id']}"
      puts "   Status: #{result['status']}"
    end
    result
  else
    puts "   ❌ Failed to create packet: #{response.code}"
    puts "   Response: #{result}"
    nil
  end
rescue StandardError => e
  puts "   ❌ Error: #{e.message}"
  nil
end

# Step 3: Try GraphQL mutation with correct structure
def create_etch_packet_graphql(api_key)
  puts "\n📝 Creating e-signature packet via GraphQL..."

  uri = URI('https://app.useanvil.com/graphql')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  # GraphQL mutation based on docs
  mutation = {
    query: <<~GRAPHQL,
      mutation CreateEtchPacket($variables: JSON) {
        createEtchPacket(variables: $variables) {
          eid
          name
          status
        }
      }
    GRAPHQL
    variables: {
      variables: {
        name: "Test Agreement via GraphQL #{Time.now.to_i}",
        isDraft: false,
        isTest: true,
        signers: [
          {
            id: 'signer1',
            name: 'Test Signer',
            email: 'test@example.com',
            signerType: 'email'
          }
        ]
      }
    }
  }

  request.body = mutation.to_json

  response = http.request(request)
  result = begin
    JSON.parse(response.body)
  rescue StandardError
    response.body
  end

  if response.code == '200'
    if result['data'] && result['data']['createEtchPacket']
      packet = result['data']['createEtchPacket']
      puts '   ✅ Packet created via GraphQL!'
      puts "   EID: #{packet['eid']}"
      puts "   Name: #{packet['name']}"
      puts "   Status: #{packet['status']}"
      packet
    else
      puts '   ⚠️  GraphQL returned no data'
      puts "   Errors: #{result['errors']}" if result['errors']
      nil
    end
  else
    puts "   ❌ GraphQL request failed: #{response.code}"
    puts "   Response: #{result}"
    nil
  end
rescue StandardError => e
  puts "   ❌ Error: #{e.message}"
  nil
end

# Main execution
puts "\nAttempting to create an e-signature packet..."

# Try REST API first (usually simpler)
packet = create_etch_packet_rest(api_key)

# Also try GraphQL
graphql_packet = create_etch_packet_graphql(api_key)

puts "\n#{'=' * 50}"
puts 'Summary'
puts '=' * 50

if packet || graphql_packet
  puts '✅ Successfully created e-signature packet!'
  puts "\n📚 Next steps:"
  puts '1. Log into Anvil: https://app.useanvil.com'
  puts '2. Navigate to the Etch section'
  puts '3. View your test packets'
  puts '4. Get signing URLs for the signers'
  puts "\n💡 Note: Since we used isTest: true, no emails were sent"
else
  puts "⚠️  Couldn't create a signature packet"
  puts "\n💡 Troubleshooting:"
  puts '1. Check if your API key has e-signature permissions'
  puts '2. Try creating a packet manually in the Anvil UI first'
  puts '3. Check the Anvil documentation for required fields'
  puts '   https://www.useanvil.com/docs/api/e-signatures'
end
