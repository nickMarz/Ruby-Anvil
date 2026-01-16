# frozen_string_literal: true

require 'openssl'

module Anvil
  class Webhook < Resources::Base
    # Webhook actions/events
    ACTIONS = %w[
      weldCreate
      forgeComplete
      weldComplete
      signerComplete
      signerUpdateStatus
      etchPacketComplete
      documentGroupCreate
      webhookTest
    ].freeze

    attr_reader :raw_payload, :token

    def initialize(payload:, token: nil, **options)
      @raw_payload = payload.is_a?(String) ? payload : payload.to_json
      @token = token

      begin
        parsed = JSON.parse(@raw_payload, symbolize_names: true)
        super(parsed, **options)
      rescue JSON::ParserError => e
        raise WebhookError, "Invalid webhook payload: #{e.message}"
      end
    end

    def action
      attributes[:action]
    end

    def data
      attributes[:data]
    end

    def timestamp
      attributes[:timestamp] || attributes[:created_at]
    end

    # Verify the webhook token
    def valid?(expected_token = nil)
      expected_token ||= Anvil.configuration.webhook_token

      raise WebhookVerificationError, 'No webhook token configured' if expected_token.nil? || expected_token.empty?

      return false unless token

      # Constant-time comparison to prevent timing attacks
      secure_compare(token, expected_token)
    end

    def valid!
      raise WebhookVerificationError, 'Invalid webhook token' unless valid?

      true
    end

    # Check if data is encrypted
    def encrypted?
      data.is_a?(String) && data.match?(%r{^[A-Za-z0-9+/=]+$})
    end

    # Decrypt the webhook data (requires RSA private key)
    def decrypt(private_key_path = nil)
      return data unless encrypted?

      private_key_path ||= ENV.fetch('ANVIL_RSA_PRIVATE_KEY_PATH', nil)

      unless private_key_path && File.exist?(private_key_path)
        raise WebhookError, 'Private key not found for decrypting webhook data'
      end

      begin
        private_key = OpenSSL::PKey::RSA.new(File.read(private_key_path))
        encrypted_data = Base64.decode64(data)
        decrypted = private_key.private_decrypt(encrypted_data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
        JSON.parse(decrypted, symbolize_names: true)
      rescue StandardError => e
        raise WebhookError, "Failed to decrypt webhook data: #{e.message}"
      end
    end

    # Helper methods for specific webhook types
    def workflow_created?
      action == 'weldCreate'
    end

    def webform_complete?
      action == 'forgeComplete'
    end

    def workflow_complete?
      action == 'weldComplete'
    end

    def signer_complete?
      action == 'signerComplete'
    end

    def signer_status_updated?
      action == 'signerUpdateStatus'
    end

    def signature_packet_complete?
      action == 'etchPacketComplete'
    end

    def document_group_created?
      action == 'documentGroupCreate'
    end

    def test?
      action == 'webhookTest'
    end

    # Extract specific data based on webhook type
    def signer_eid
      data[:signerEid] if signer_complete? || signer_status_updated?
    end

    def packet_eid
      data[:packetEid] if signature_packet_complete? || signer_complete?
    end

    def workflow_eid
      data[:weldEid] || data[:eid] if workflow_created? || workflow_complete?
    end

    def webform_eid
      data[:forgeEid] if webform_complete?
    end

    def signer_status
      data[:status] if signer_status_updated?
    end

    def signer_name
      data[:signerName] if signer_complete? || signer_status_updated?
    end

    def signer_email
      data[:signerEmail] if signer_complete? || signer_status_updated?
    end

    class << self
      # Verify and parse a webhook request
      #
      # @param request [ActionDispatch::Request, Rack::Request] The incoming request
      # @return [Webhook] The parsed and verified webhook
      def from_request(request)
        payload = request.body.read
        token = extract_token(request)

        webhook = new(payload: payload, token: token)
        webhook.valid!
        webhook
      end

      # Create a test webhook for development
      def create_test(action: 'webhookTest', data: {})
        payload = {
          action: action,
          data: data,
          timestamp: Time.now.iso8601
        }

        new(
          payload: payload.to_json,
          token: Anvil.configuration.webhook_token
        )
      end

      private

      def extract_token(request)
        # Token can be in header or params
        request.headers['X-Anvil-Token'] ||
          request.params['token'] ||
          request.params['anvil_token']
      end
    end

    private

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack('C*')
      r = b.unpack('C*')
      result = 0

      l.zip(r).each { |x, y| result |= x ^ y }
      result.zero?
    end
  end
end
