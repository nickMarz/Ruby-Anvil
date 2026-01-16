#!/usr/bin/env ruby
# frozen_string_literal: true

# Test e-signature functionality with Anvil API

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
puts "Anvil E-Signature Test"
puts "=" * 50

# Option 1: Create a test signature packet with a generated PDF
def create_test_packet_with_generated_pdf
  puts "\n📝 Creating a test signature packet..."

  # First, generate a simple agreement PDF
  puts "📄 Generating agreement PDF..."

  agreement_html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Test Agreement</title>
    </head>
    <body style="font-family: Arial, sans-serif; padding: 40px;">
      <h1 style="color: #333;">Service Agreement</h1>

      <p><strong>Date:</strong> #{Date.today.strftime('%B %d, %Y')}</p>

      <h2>Terms and Conditions</h2>
      <p>This is a test agreement for demonstration purposes.</p>

      <h3>1. Services</h3>
      <p>The service provider agrees to provide software development services.</p>

      <h3>2. Payment</h3>
      <p>Payment terms will be NET 30.</p>

      <h3>3. Confidentiality</h3>
      <p>Both parties agree to maintain confidentiality.</p>

      <div style="margin-top: 100px;">
        <p><strong>Signature Fields:</strong></p>

        <div style="margin-top: 50px;">
          <p>_______________________________<br/>
          Client Signature<br/>
          Date: ________________</p>
        </div>

        <div style="margin-top: 50px;">
          <p>_______________________________<br/>
          Provider Signature<br/>
          Date: ________________</p>
        </div>
      </div>
    </body>
    </html>
  HTML

  css = <<~CSS
    body {
      line-height: 1.6;
      color: #333;
    }
    h1 {
      border-bottom: 2px solid #007bff;
      padding-bottom: 10px;
    }
    h2, h3 {
      color: #555;
    }
    p {
      margin: 10px 0;
    }
  CSS

  # Generate the PDF
  pdf = Anvil::PDF.generate_from_html(
    html: agreement_html,
    css: css,
    title: 'Service Agreement'
  )

  # Save it temporarily
  pdf_filename = "agreement_#{Time.now.to_i}.pdf"
  pdf.save_as(pdf_filename)
  puts "✅ Agreement PDF saved as: #{pdf_filename}"

  # Note: In a real scenario, you would:
  # 1. Upload this PDF to Anvil to get a template ID
  # 2. Or use an existing template ID from your Anvil account

  puts "\n⚠️  Note: To create an actual signature packet, you need:"
  puts "   1. A PDF template ID from your Anvil account"
  puts "   2. Or upload the generated PDF to Anvil first"

  pdf_filename
end

# Option 2: Create a signature packet with a template ID (if you have one)
def create_signature_packet_with_template(template_id = nil)
  if template_id.nil?
    puts "\n❗ To test signatures with a template, you need a PDF template ID"
    puts "   1. Log into Anvil: https://app.useanvil.com"
    puts "   2. Upload a PDF template"
    puts "   3. Get the template ID"
    puts "   4. Pass it to this function"
    return nil
  end

  puts "\n🚀 Creating signature packet with template: #{template_id}"

  begin
    packet = Anvil::Signature.create(
      name: "Test Agreement - #{Date.today}",

      # Define signers
      signers: [
        {
          name: 'John Doe',
          email: 'john.test@example.com',
          role: 'client',
          signer_type: 'email'
        },
        {
          name: 'Jane Smith',
          email: 'jane.test@example.com',
          role: 'provider',
          signer_type: 'email'
        }
      ],

      # Reference the PDF template
      files: [
        {
          type: :pdf,
          id: template_id
        }
      ],

      # Start as draft (signers won't be notified yet)
      is_draft: true,

      # Custom email settings
      email_subject: 'Please sign the test agreement',
      email_body: 'This is a test signature request from the Anvil Ruby gem.',

      # Webhook for status updates (optional)
      # webhook_url: 'https://your-app.com/webhooks/anvil'
    )

    puts "✅ Signature packet created successfully!"
    puts "\n📋 Packet Details:"
    puts "   ID: #{packet.eid}"
    puts "   Name: #{packet.name}"
    puts "   Status: #{packet.status}"
    puts "   Signers: #{packet.signers.count}"

    # Get signing URLs for each signer
    puts "\n🔗 Signing URLs:"
    packet.signers.each do |signer|
      url = signer.signing_url
      puts "\n   👤 #{signer.name} (#{signer.email})"
      puts "      Status: #{signer.status}"
      puts "      URL: #{url}"
      puts "      -> Send this URL to the signer to collect their signature"
    end

    packet

  rescue Anvil::Error => e
    puts "❌ Error creating signature packet: #{e.message}"
    nil
  end
end

# Option 3: Simple test with mock data (for demonstration)
def demonstrate_signature_api
  puts "\n📚 E-Signature API Demonstration"
  puts "=" * 40

  puts "\nThe Anvil::Signature class provides these methods:"
  puts "\n1️⃣  Create a signature packet:"
  puts <<~RUBY
    packet = Anvil::Signature.create(
      name: 'Employment Agreement',
      signers: [
        { name: 'John Doe', email: 'john@example.com', role: 'employee' },
        { name: 'Jane HR', email: 'hr@company.com', role: 'hr_manager' }
      ],
      files: [{ type: :pdf, id: 'your_template_id' }],
      is_draft: true  # Start as draft
    )
  RUBY

  puts "\n2️⃣  Get signing URLs:"
  puts <<~RUBY
    packet.signers.each do |signer|
      puts "\#{signer.name}: \#{signer.signing_url}"
    end
  RUBY

  puts "\n3️⃣  Check packet status:"
  puts <<~RUBY
    packet.reload!
    if packet.complete?
      puts "All signatures collected!"
    elsif packet.in_progress?
      puts "Still collecting signatures..."
    end
  RUBY

  puts "\n4️⃣  Find existing packet:"
  puts <<~RUBY
    packet = Anvil::Signature.find('packet_eid_here')
    puts "Status: \#{packet.status}"
  RUBY

  puts "\n5️⃣  List all packets:"
  puts <<~RUBY
    packets = Anvil::Signature.list(limit: 10, status: 'sent')
    packets.each do |p|
      puts "\#{p.name} - \#{p.status}"
    end
  RUBY
end

# Main execution
begin
  # Show API demonstration
  demonstrate_signature_api

  # Generate a test PDF
  pdf_file = create_test_packet_with_generated_pdf

  # Try to create an actual signature packet
  # Replace 'your_template_id' with an actual template ID from your Anvil account
  template_id = ENV['ANVIL_TEMPLATE_ID'] || 'your_template_id_here'

  if template_id != 'your_template_id_here'
    packet = create_signature_packet_with_template(template_id)

    if packet
      puts "\n🎯 Next Steps:"
      puts "1. Send the signing URLs to the signers (or test them yourself)"
      puts "2. Complete the signatures"
      puts "3. Check the packet status with: packet.reload!"
      puts "4. Download signed documents when complete"
    end
  else
    puts "\n💡 To test with real signatures:"
    puts "1. Log into Anvil: https://app.useanvil.com"
    puts "2. Create or upload a PDF template"
    puts "3. Get the template ID from the template settings"
    puts "4. Either:"
    puts "   - Set ANVIL_TEMPLATE_ID in your .env file"
    puts "   - Or replace 'your_template_id_here' in this script"
    puts "5. Run this script again"
  end

  puts "\n✅ E-signature test complete!"

rescue Anvil::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check your API key in .env"
rescue Anvil::Error => e
  puts "❌ Anvil error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end