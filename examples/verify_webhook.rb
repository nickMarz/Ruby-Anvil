#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'anvil'
require 'webrick'
require 'json'

# Example: Webhook verification and handling
#
# This example shows how to:
# 1. Set up a webhook endpoint
# 2. Verify webhook authenticity
# 3. Handle different webhook events
# 4. Process webhook data

# Configure Anvil with webhook token
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.webhook_token = ENV['ANVIL_WEBHOOK_TOKEN'] || 'your_webhook_token_here'
  config.environment = :development
end

# Example webhook handler class
class WebhookHandler
  def handle(webhook)
    puts "\n📨 Received webhook:"
    puts "   Action: #{webhook.action}"
    puts "   Timestamp: #{webhook.timestamp}"

    # Handle different webhook types
    case webhook.action
    when 'signerComplete'
      handle_signer_complete(webhook)
    when 'signerUpdateStatus'
      handle_signer_status_update(webhook)
    when 'etchPacketComplete'
      handle_packet_complete(webhook)
    when 'weldCreate'
      handle_workflow_created(webhook)
    when 'weldComplete'
      handle_workflow_complete(webhook)
    when 'forgeComplete'
      handle_webform_complete(webhook)
    when 'documentGroupCreate'
      handle_document_group_created(webhook)
    when 'webhookTest'
      handle_test_webhook(webhook)
    else
      puts "   ⚠️  Unknown webhook action: #{webhook.action}"
    end
  end

  private

  def handle_signer_complete(webhook)
    puts "✅ Signer completed!"
    puts "   Signer: #{webhook.signer_name} (#{webhook.signer_email})"
    puts "   Signer ID: #{webhook.signer_eid}"
    puts "   Packet ID: #{webhook.packet_eid}"

    # In a real app, you might:
    # - Update database records
    # - Send notification emails
    # - Trigger next workflow step
  end

  def handle_signer_status_update(webhook)
    puts "📊 Signer status updated"
    puts "   Signer: #{webhook.signer_name}"
    puts "   New status: #{webhook.signer_status}"

    case webhook.signer_status
    when 'viewed'
      puts "   👀 Signer has viewed the document"
    when 'signed'
      puts "   ✍️  Signer has signed"
    end
  end

  def handle_packet_complete(webhook)
    puts "🎉 Signature packet complete!"
    puts "   Packet ID: #{webhook.packet_eid}"

    # All signatures collected - download final documents
    # packet = Anvil::Signature.find(webhook.packet_eid)
    # download_signed_documents(packet)
  end

  def handle_workflow_created(webhook)
    puts "🔧 Workflow created"
    puts "   Workflow ID: #{webhook.workflow_eid}"
  end

  def handle_workflow_complete(webhook)
    puts "✅ Workflow complete!"
    puts "   Workflow ID: #{webhook.workflow_eid}"
  end

  def handle_webform_complete(webhook)
    puts "📝 Webform completed"
    puts "   Webform ID: #{webhook.webform_eid}"
  end

  def handle_document_group_created(webhook)
    puts "📄 Document group created"
    data = webhook.data
    puts "   Group ID: #{data[:documentGroupEid]}" if data[:documentGroupEid]
  end

  def handle_test_webhook(webhook)
    puts "🧪 Test webhook received!"
    puts "   Your webhook endpoint is working correctly"
  end
end

# Example: Simple webhook server for testing
class WebhookServer
  def initialize(port: 4567)
    @port = port
    @handler = WebhookHandler.new
  end

  def start
    server = WEBrick::HTTPServer.new(Port: @port)

    # Mount webhook endpoint
    server.mount_proc '/webhooks/anvil' do |req, res|
      begin
        # Parse the webhook
        webhook = Anvil::Webhook.new(
          payload: req.body,
          token: req.query['token'] || req.header['x-anvil-token']
        )

        # Verify the webhook
        if webhook.valid?
          puts "✅ Webhook verified successfully"

          # Handle encrypted data if present
          if webhook.encrypted?
            puts "🔐 Webhook data is encrypted"
            # To decrypt, you need your RSA private key:
            # decrypted_data = webhook.decrypt('/path/to/private_key.pem')
          end

          # Process the webhook
          @handler.handle(webhook)

          # Return success response
          res.status = 204  # No Content
        else
          puts "❌ Invalid webhook token!"
          res.status = 401  # Unauthorized
          res.body = 'Invalid token'
        end
      rescue Anvil::WebhookError => e
        puts "❌ Webhook error: #{e.message}"
        res.status = 400
        res.body = e.message
      rescue => e
        puts "❌ Unexpected error: #{e.message}"
        res.status = 500
        res.body = 'Internal server error'
      end
    end

    # Test endpoint
    server.mount_proc '/test' do |req, res|
      res.body = 'Webhook server is running!'
    end

    puts "🚀 Webhook server running on http://localhost:#{@port}"
    puts "📍 Webhook endpoint: http://localhost:#{@port}/webhooks/anvil"
    puts "   Configure this URL in your Anvil account settings"
    puts "\nPress Ctrl+C to stop the server"

    trap('INT') { server.shutdown }
    server.start
  end
end

# Example: Rails controller for webhooks
def rails_controller_example
  puts <<~RUBY
    # app/controllers/anvil_webhooks_controller.rb
    class AnvilWebhooksController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        webhook = Anvil::Webhook.new(
          payload: request.body.read,
          token: params[:token]
        )

        if webhook.valid?
          process_webhook(webhook)
          head :no_content
        else
          Rails.logger.error "Invalid Anvil webhook token"
          head :unauthorized
        end
      rescue Anvil::WebhookError => e
        Rails.logger.error "Webhook error: \#{e.message}"
        head :bad_request
      end

      private

      def process_webhook(webhook)
        # Process webhook based on action
        case webhook.action
        when 'signerComplete'
          SignerCompleteJob.perform_later(webhook.data)
        when 'etchPacketComplete'
          PacketCompleteJob.perform_later(webhook.data)
        # ... handle other webhook types
        end
      end
    end

    # config/routes.rb
    post 'webhooks/anvil', to: 'anvil_webhooks#create'
  RUBY
end

# Example: Create a test webhook
def create_test_webhook
  puts "\n🧪 Creating test webhook..."

  webhook = Anvil::Webhook.create_test(
    action: 'signerComplete',
    data: {
      signerEid: 'test_signer_123',
      packetEid: 'test_packet_456',
      signerName: 'Test User',
      signerEmail: 'test@example.com'
    }
  )

  puts "Test webhook created:"
  puts "   Action: #{webhook.action}"
  puts "   Valid: #{webhook.valid?}"

  webhook
end

# Run the example
if __FILE__ == $0
  puts "=" * 50
  puts "Anvil Webhook Verification Example"
  puts "=" * 50

  choice = ARGV[0]

  case choice
  when 'server'
    # Start webhook server
    server = WebhookServer.new(port: 4567)
    server.start

  when 'test'
    # Create and verify a test webhook
    webhook = create_test_webhook
    handler = WebhookHandler.new
    handler.handle(webhook)

  when 'rails'
    # Show Rails controller example
    puts "\n📱 Rails Controller Example:"
    puts "=" * 40
    rails_controller_example

  else
    puts "\nUsage:"
    puts "  ruby #{__FILE__} server  # Start webhook test server"
    puts "  ruby #{__FILE__} test    # Create and handle test webhook"
    puts "  ruby #{__FILE__} rails   # Show Rails controller example"
    puts "\nEnvironment variables:"
    puts "  ANVIL_API_KEY      - Your Anvil API key"
    puts "  ANVIL_WEBHOOK_TOKEN - Your webhook verification token"
  end
end