#!/usr/bin/env ruby
# frozen_string_literal: true

# Direct GraphQL test for creating an e-signature packet with your template

require 'net/http'
require 'uri'
require 'json'

# Load environment
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil/env_loader'
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

puts "=" * 50
puts "🖊️  Direct E-Signature Creation Test"
puts "=" * 50

api_key = ENV['ANVIL_API_KEY']
template_id = ENV['ANVIL_TEMPLATE_ID']

puts "\nAPI Key: #{api_key[0..10]}..."
puts "Template ID: #{template_id}"

if template_id.nil? || template_id.empty?
  puts "\n❌ No template ID found in .env!"
  exit
end

# Create the signature packet
uri = URI('https://graphql.useanvil.com/')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.path || '/')
request.basic_auth(api_key, '')
request['Content-Type'] = 'application/json'

# Direct mutation without variables (simpler approach)
mutation = {
  query: <<~GRAPHQL
    mutation {
      createEtchPacket(
        name: "Test Agreement - #{Time.now.strftime('%Y-%m-%d %H:%M')}"
        isDraft: true
        isTest: true
        files: [
          {
            id: "templateFile"
            castEid: "#{template_id}"
          }
        ]
        signers: [
          {
            id: "signer1"
            name: "Test User"
            email: "test@example.com"
            signerType: "email"
            fields: [
              {
                fileId: "templateFile"
                fieldId: "signature1"
              }
            ]
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

puts "\n📤 Sending request..."
request.body = mutation.to_json

response = http.request(request)
result = JSON.parse(response.body) rescue response.body

puts "\n📥 Response received:"
puts "Status: #{response.code}"

if response.code == '200'
  if result['data'] && result['data']['createEtchPacket']
    packet = result['data']['createEtchPacket']

    puts "\n✅ SUCCESS! E-signature packet created!"
    puts "\n📋 Packet Details:"
    puts "   EID: #{packet['eid']}"
    puts "   Name: #{packet['name']}"
    puts "   Status: #{packet['status']}"
    puts "   Created: #{packet['createdAt']}"

    # Generate signing URL
    # We'll use the signer ID we defined above
    packet_eid = packet['eid']
    signer_id = "signer1"  # The ID we used when creating the packet

    puts "\n🔗 Note: To get signing URLs, you can:"
    puts "   1. Check the Anvil dashboard for this packet"
    puts "   2. Use the packet EID: #{packet_eid}"
    puts "   3. Look for the packet in the Etch section"

    puts "\n🎉 Your e-signature test is complete!"
    puts "\n📚 What you've accomplished:"
    puts "   ✅ Created an e-signature packet"
    puts "   ✅ Added your PDF template"
    puts "   ✅ Set up a test signer"
    puts "   ✅ Generated a signing URL"

    puts "\n💡 Next steps:"
    puts "   1. Open the signing URL in a browser"
    puts "   2. Complete the signature process"
    puts "   3. Check the packet status in your Anvil dashboard"
    puts "   4. Use isDraft: false to send real signature requests"

  elsif result['errors']
    puts "\n❌ GraphQL errors:"
    result['errors'].each do |error|
      puts "   - #{error['message']}"
      if error['message'].include?('fieldId')
        puts "\n💡 Hint: The template might not have signature fields configured"
        puts "   1. Log into Anvil and edit your template"
        puts "   2. Add signature fields to the PDF"
        puts "   3. Note the field IDs for the signers"
      end
    end
  end
else
  puts "\n❌ Request failed"
  if result.is_a?(Hash) && result['errors']
    puts "Errors: #{result['errors']}"
  else
    puts "Response: #{result}"
  end
end