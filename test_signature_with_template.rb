#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Anvil E-Signatures with a Template
# First, add your template ID to .env: ANVIL_TEMPLATE_ID=your_cast_eid

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

# Configure Anvil
Anvil.configure do |config|
  config.api_key = ENV.fetch('ANVIL_API_KEY', nil)
  config.environment = :development
end

puts '=' * 50
puts '🖊️  Anvil E-Signature with Template'
puts '=' * 50

template_id = ENV.fetch('ANVIL_TEMPLATE_ID', nil)

if template_id.nil? || template_id.empty?
  puts "\n⚠️  No template ID found!"
  puts "\nTo test e-signatures:"
  puts '1. Log into Anvil: https://app.useanvil.com'
  puts "2. Go to 'PDF Templates' and upload a PDF"
  puts '3. Click on the template to view details'
  puts "4. Copy the 'Cast EID' (looks like: XnuTZKVNA1Mljsu999od)"
  puts '5. Add to your .env file:'
  puts '   ANVIL_TEMPLATE_ID=your_cast_eid_here'
  puts '6. Run this script again'
  exit
end

puts "\nUsing template: #{template_id}"

begin
  # Use our Ruby gem's Signature class
  packet = Anvil::Signature.create(
    name: "Test Agreement - #{DateTime.now.strftime('%Y-%m-%d %H:%M')}",

    signers: [
      {
        name: 'John Doe',
        email: 'john.test@example.com',
        role: 'signer1',
        signer_type: 'email'
      },
      {
        name: 'Jane Smith',
        email: 'jane.test@example.com',
        role: 'signer2',
        signer_type: 'email'
      }
    ],

    # Use your template
    files: [
      {
        type: :pdf,
        id: template_id
      }
    ],

    # Start as draft so no emails are sent yet
    is_draft: true,

    # Custom email text
    email_subject: 'Test Signature Request from Ruby Gem',
    email_body: 'Please sign this test document.'
  )

  puts "\n✅ Signature packet created successfully!"
  puts "\n📋 Packet Details:"
  puts "   ID: #{packet.eid}"
  puts "   Name: #{packet.name}"
  puts "   Status: #{packet.status}"

  # Get signing URLs
  puts "\n🔗 Signing URLs:"
  packet.signers.each do |signer|
    puts "\n   👤 #{signer.name} (#{signer.email})"
    puts "      Status: #{signer.status}"

    # Generate signing URL
    url = signer.signing_url
    puts "      URL: #{url}"
  end

  puts "\n🎯 Next Steps:"
  puts '1. Copy a signing URL above'
  puts '2. Open it in a browser to test the signing experience'
  puts '3. Or change is_draft to false to send real emails'
  puts '4. Check packet status: packet.reload!'
rescue Anvil::ValidationError => e
  puts "\n❌ Validation error: #{e.message}"
  puts 'Make sure your template ID is correct'
rescue Anvil::AuthenticationError => e
  puts "\n❌ Authentication error: #{e.message}"
rescue Anvil::Error => e
  puts "\n❌ Error: #{e.message}"
  puts "\n💡 If the template ID doesn't work:"
  puts "   - Make sure it's the 'Cast EID' not the template name"
  puts '   - Check that the template has signature fields configured'
rescue StandardError => e
  puts "\n❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end
