#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Anvil API connection and endpoints

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'
require 'net/http'
require 'uri'
require 'json'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

puts "=" * 50
puts "Anvil API Connection Test"
puts "=" * 50

api_key = ENV['ANVIL_API_KEY']
puts "\nUsing API Key: #{api_key[0..10]}..."

# Test 1: Direct REST API call (we know this works)
def test_rest_api(api_key)
  puts "\n1️⃣  Testing REST API (PDF Generation)..."

  uri = URI('https://app.useanvil.com/api/v1/generate-pdf')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'
  request.body = {
    type: 'markdown',
    data: [{ content: '# Test\nThis is a test.' }]
  }.to_json

  response = http.request(request)

  if response.code == '200'
    puts "   ✅ REST API works! (PDF generated)"
    true
  else
    puts "   ❌ REST API failed: #{response.code}"
    puts "   Response: #{response.body[0..200]}"
    false
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
  false
end

# Test 2: GraphQL API
def test_graphql_api(api_key)
  puts "\n2️⃣  Testing GraphQL API..."

  uri = URI('https://app.useanvil.com/graphql')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(api_key, '')
  request['Content-Type'] = 'application/json'

  # Simple query to test GraphQL
  query = {
    query: <<~GRAPHQL
      query {
        currentUser {
          eid
          name
        }
      }
    GRAPHQL
  }.to_json

  request.body = query

  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    if data['data']
      puts "   ✅ GraphQL API works!"
      puts "   User: #{data['data']['currentUser']}"
      true
    else
      puts "   ⚠️  GraphQL responded but no data"
      puts "   Response: #{response.body[0..200]}"
      false
    end
  else
    puts "   ❌ GraphQL API failed: #{response.code}"
    puts "   Response: #{response.body[0..200]}"
    false
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
  false
end

# Test 3: Using the Ruby gem client
def test_gem_client(api_key)
  puts "\n3️⃣  Testing Ruby Gem Client..."

  Anvil.configure do |config|
    config.api_key = api_key
    config.environment = :development
  end

  # Test PDF generation (we know this works)
  pdf = Anvil::PDF.generate_from_markdown('# Test Document')
  puts "   ✅ Gem client works! (PDF generated)"
  true
rescue => e
  puts "   ❌ Gem client error: #{e.message}"
  false
end

# Run all tests
rest_ok = test_rest_api(api_key)
graphql_ok = test_graphql_api(api_key)
gem_ok = test_gem_client(api_key)

puts "\n" + "=" * 50
puts "Test Results:"
puts "=" * 50
puts "REST API:    #{rest_ok ? '✅' : '❌'}"
puts "GraphQL API: #{graphql_ok ? '✅' : '❌'}"
puts "Ruby Gem:    #{gem_ok ? '✅' : '❌'}"

if graphql_ok
  puts "\n✅ GraphQL is working! We can proceed with e-signatures."
else
  puts "\n⚠️  GraphQL is not working. E-signatures require GraphQL."
  puts "\nPossible issues:"
  puts "1. GraphQL might require a different authentication method"
  puts "2. The endpoint might be different"
  puts "3. Your account might not have GraphQL access"
  puts "\n💡 Try the REST API e-signature endpoints instead:"
  puts "   POST https://app.useanvil.com/api/v1/etch-packets"
end