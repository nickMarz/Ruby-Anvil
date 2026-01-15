#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'anvil'

# Example: Create and manage e-signature packets
#
# This example demonstrates how to:
# 1. Create an e-signature packet
# 2. Add signers
# 3. Generate signing URLs
# 4. Check signature status

# Configure Anvil
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.environment = :development
end

# Example: Create a signature packet for an employment agreement
def create_employment_agreement
  puts "📝 Creating e-signature packet for employment agreement..."

  # Create the signature packet
  packet = Anvil::Signature.create(
    name: 'Employment Agreement - John Doe',

    # Define signers
    signers: [
      {
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'employee',
        signer_type: 'email'  # Email-based signing
      },
      {
        name: 'Jane Smith',
        email: 'jane.smith@company.com',
        role: 'hr_manager',
        signer_type: 'email'
      }
    ],

    # Specify files to sign (using a PDF template)
    files: [
      {
        type: :pdf,
        id: 'your_template_id_here'  # Replace with your PDF template ID
      }
    ],

    # Optional: Set as draft first (signers won't be notified yet)
    is_draft: true,

    # Optional: Custom email settings
    email_subject: 'Please sign your employment agreement',
    email_body: 'Dear {{signerName}}, Please review and sign the attached employment agreement. Thank you!',

    # Optional: Webhook URL for status updates
    webhook_url: 'https://yourapp.com/webhooks/anvil'
  )

  puts "✅ Signature packet created!"
  puts "📋 Packet ID: #{packet.eid}"
  puts "📊 Status: #{packet.status}"
  puts "👥 Signers: #{packet.signers.count}"

  packet
end

# Example: Get signing URLs for signers
def generate_signing_urls(packet)
  puts "\n🔗 Generating signing URLs..."

  packet.signers.each do |signer|
    url = signer.signing_url(
      client_user_id: "user_#{signer.email}" # Optional: Your internal user ID
    )

    puts "\n👤 Signer: #{signer.name} (#{signer.email})"
    puts "📊 Status: #{signer.status}"
    puts "🔗 Signing URL: #{url}"
    puts "   Send this URL to the signer to complete their signature"
  end
end

# Example: Check signature packet status
def check_packet_status(packet_eid)
  puts "\n🔍 Checking packet status..."

  # Reload the packet to get latest status
  packet = Anvil::Signature.find(packet_eid)

  puts "📋 Packet: #{packet.name}"
  puts "📊 Overall Status: #{packet.status}"

  # Check individual signer status
  packet.signers.each do |signer|
    status_emoji = case signer.status
                   when 'complete' then '✅'
                   when 'sent' then '📧'
                   when 'viewed' then '👀'
                   else '⏳'
                   end

    puts "#{status_emoji} #{signer.name}: #{signer.status}"

    if signer.complete?
      puts "   Completed at: #{signer.completed_at}"
    end
  end

  # Check if entire packet is complete
  if packet.complete?
    puts "\n🎉 All signatures collected!"
    # You can now download the signed documents
  elsif packet.partially_complete?
    puts "\n⏳ Waiting for remaining signatures..."
  end

  packet
end

# Example: List all signature packets
def list_signature_packets
  puts "\n📑 Listing signature packets..."

  packets = Anvil::Signature.list(
    limit: 10,
    status: 'sent'  # Filter by status (optional)
  )

  if packets.empty?
    puts "No signature packets found"
  else
    packets.each do |packet|
      puts "\n📋 #{packet.name}"
      puts "   ID: #{packet.eid}"
      puts "   Status: #{packet.status}"
      puts "   Created: #{packet.created_at}"
    end
  end
end

# Example: Send reminders (by recreating signing URLs)
def send_reminder(packet)
  puts "\n📧 Sending reminders to incomplete signers..."

  packet.signers.each do |signer|
    next if signer.complete?

    url = signer.signing_url
    puts "🔔 Reminder for #{signer.name} (#{signer.email})"
    puts "   Signing URL: #{url}"

    # In a real application, you would send an email here
    # using your email service (ActionMailer, SendGrid, etc.)
  end
end

# Run the example
begin
  puts "=" * 50
  puts "Anvil E-Signature Example"
  puts "=" * 50

  # Create a new signature packet
  packet = create_employment_agreement

  # Generate signing URLs
  generate_signing_urls(packet)

  # Simulate checking status after some time
  puts "\n⏰ (In a real app, you'd check this later...)"
  check_packet_status(packet.eid)

  # List all packets
  list_signature_packets

  # Send reminders if needed
  if packet.in_progress?
    send_reminder(packet)
  end

  puts "\n✅ E-signature example completed!"

rescue Anvil::ValidationError => e
  puts "❌ Validation error: #{e.message}"
  puts "Errors: #{e.errors.inspect}" if e.errors.any?
rescue Anvil::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check your API key"
rescue Anvil::Error => e
  puts "❌ Anvil error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end