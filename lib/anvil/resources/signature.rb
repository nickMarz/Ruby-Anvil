# frozen_string_literal: true

module Anvil
  class Signature < Resources::Base
    # Etch packet statuses
    STATUSES = %w[draft sent partial_complete complete].freeze

    def id
      attributes[:eid] || attributes[:id]
    end

    def eid
      attributes[:eid]
    end

    def status
      attributes[:status]
    end

    def name
      attributes[:name]
    end

    # Check packet status
    def draft?
      status == 'draft'
    end

    def sent?
      status == 'sent'
    end

    def partially_complete?
      status == 'partial_complete'
    end

    def complete?
      status == 'complete'
    end

    def completed?
      complete?
    end

    # Has the packet been sent to signers?
    def in_progress?
      sent? || partially_complete?
    end

    # Get signing URL for a specific signer
    def signing_url(signer_id:, client_user_id: nil)
      self.class.generate_signing_url(
        packet_eid: eid,
        signer_eid: signer_id,
        client_user_id: client_user_id,
        client: client
      )
    end

    # Get all signers
    def signers
      Array(attributes[:signers]).map do |signer|
        SignatureSigner.new(signer, packet: self)
      end
    end

    # Get documents
    def documents
      Array(attributes[:documents])
    end

    # Reload from API
    def reload!
      refreshed = self.class.find(eid, client: client)
      @attributes = refreshed.attributes
      self
    end

    # Update the signature packet
    #
    # @param name [String] Updated name for the packet
    # @param signers [Array<Hash>] Updated signer information
    # @param options [Hash] Additional update options
    # @return [Signature] The updated signature packet
    def update(name: nil, signers: nil, **options)
      self.class.update(
        eid: eid,
        name: name,
        signers: signers,
        client: client,
        **options
      )
    end

    # Send a draft packet to signers
    #
    # @param options [Hash] Send options
    # @option options [String] :email_subject Custom email subject
    # @option options [String] :email_body Custom email body
    # @return [Signature] The sent signature packet
    # @raise [APIError] If packet is not in draft state
    def send!(**options)
      raise APIError, "Only draft packets can be sent. Current status: #{status}" unless draft?

      self.class.send_packet(
        eid: eid,
        client: client,
        **options
      )
    end

    # Delete the signature packet
    #
    # @return [Boolean] true if deletion was successful
    # @raise [APIError] If deletion fails
    def delete!
      self.class.delete_packet(eid: eid, client: client)
    end

    # Skip a signer in the signature flow
    #
    # @param signer_eid [String] The signer EID to skip
    # @return [Signature] The updated signature packet
    def skip_signer(signer_eid)
      self.class.skip_signer(
        packet_eid: eid,
        signer_eid: signer_eid,
        client: client
      )
    end

    # Send a reminder notification to a signer
    #
    # @param signer_eid [String] The signer EID to notify
    # @return [Boolean] true if notification was sent
    def notify_signer(signer_eid)
      self.class.notify_signer(
        packet_eid: eid,
        signer_eid: signer_eid,
        client: client
      )
    end

    # Void the document group (cancel signed documents)
    #
    # @param reason [String] Reason for voiding (optional)
    # @return [Boolean] true if voiding was successful
    def void!(reason: nil)
      self.class.void_document_group(
        eid: eid,
        reason: reason,
        client: client
      )
    end

    # Expire all active signing tokens/sessions
    #
    # @return [Boolean] true if tokens were expired
    def expire_tokens!
      self.class.expire_signer_tokens(
        eid: eid,
        client: client
      )
    end

    class << self
      # Create a new signature packet
      #
      # @param name [String] Name of the packet
      # @param signers [Array<Hash>] Array of signer information
      # @param files [Array<Hash>] Array of files to sign
      # @param options [Hash] Additional options
      # @return [Signature] The created signature packet
      def create(name:, signers:, files: nil, **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = build_create_payload(name, signers, files, options)

        # Use full GraphQL endpoint URL
        response = client.post('https://graphql.useanvil.com/', {
                                 query: create_packet_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        unless data[:data] && data[:data][:createEtchPacket]
          raise APIError, "Failed to create signature packet: #{data[:errors]}"
        end

        new(data[:data][:createEtchPacket], client: client)
      end

      # Find a signature packet by ID
      def find(packet_eid, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: find_packet_query,
                                 variables: { eid: packet_eid }
                               })

        data = response.data
        raise NotFoundError, "Signature packet not found: #{packet_eid}" unless data[:data] && data[:data][:etchPacket]

        new(data[:data][:etchPacket], client: client)
      end

      # List all signature packets
      def list(limit: 10, offset: 0, status: nil, client: nil)
        client ||= self.client

        variables = { limit: limit, offset: offset }
        variables[:status] = status if status

        response = client.post('https://graphql.useanvil.com/', {
                                 query: list_packets_query,
                                 variables: variables
                               })

        data = response.data
        if data[:data] && data[:data][:etchPackets]
          data[:data][:etchPackets].map { |packet| new(packet, client: client) }
        else
          []
        end
      end

      # Generate a signing URL for a signer
      def generate_signing_url(packet_eid:, signer_eid:, client_user_id: nil, client: nil)
        client ||= self.client

        payload = {
          packetEid: packet_eid,
          signerEid: signer_eid
        }
        payload[:clientUserId] = client_user_id if client_user_id

        response = client.post('https://graphql.useanvil.com/', {
                                 query: generate_url_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        raise APIError, 'Failed to generate signing URL' unless data[:data] && data[:data][:generateEtchSignURL]

        data[:data][:generateEtchSignURL][:url]
      end

      # Update an existing signature packet
      #
      # @param eid [String] The packet EID to update
      # @param name [String] Updated name for the packet (optional)
      # @param signers [Array<Hash>] Updated signer information (optional)
      # @param options [Hash] Additional options
      # @return [Signature] The updated signature packet
      def update(eid:, name: nil, signers: nil, client: nil, **options)
        client ||= self.client

        payload = { eid: eid }
        payload[:name] = name if name
        payload[:signers] = build_signers_payload(signers) if signers
        payload[:signatureEmailSubject] = options[:email_subject] if options[:email_subject]
        payload[:signatureEmailBody] = options[:email_body] if options[:email_body]
        payload[:webhookURL] = options[:webhook_url] if options[:webhook_url]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: update_packet_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        unless data[:data] && data[:data][:updateEtchPacket]
          raise APIError, "Failed to update signature packet: #{data[:errors]}"
        end

        new(data[:data][:updateEtchPacket], client: client)
      end

      # Send a draft packet to signers
      #
      # @param eid [String] The packet EID to send
      # @param options [Hash] Send options
      # @return [Signature] The sent signature packet
      def send_packet(eid:, client: nil, **options)
        client ||= self.client

        payload = { eid: eid }
        payload[:signatureEmailSubject] = options[:email_subject] if options[:email_subject]
        payload[:signatureEmailBody] = options[:email_body] if options[:email_body]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: send_packet_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        unless data[:data] && data[:data][:sendEtchPacket]
          raise APIError, "Failed to send signature packet: #{data[:errors]}"
        end

        new(data[:data][:sendEtchPacket], client: client)
      end

      # Delete a signature packet
      #
      # @param eid [String] The packet EID to delete
      # @return [Boolean] true if deletion was successful
      def delete_packet(eid:, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: delete_packet_mutation,
                                 variables: { eid: eid }
                               })

        data = response.data
        unless data[:data] && data[:data][:removeEtchPacket]
          raise APIError, "Failed to delete signature packet: #{data[:errors]}"
        end

        data[:data][:removeEtchPacket][:ok] || true
      end

      # Skip a signer in the signature flow
      #
      # @param packet_eid [String] The packet EID
      # @param signer_eid [String] The signer EID to skip
      # @return [Signature] The updated signature packet
      def skip_signer(packet_eid:, signer_eid:, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: skip_signer_mutation,
                                 variables: {
                                   eid: packet_eid,
                                   signerEid: signer_eid
                                 }
                               })

        data = response.data
        raise APIError, "Failed to skip signer: #{data[:errors]}" unless data[:data] && data[:data][:skipSigner]

        new(data[:data][:skipSigner], client: client)
      end

      # Send a reminder notification to a signer
      #
      # @param packet_eid [String] The packet EID
      # @param signer_eid [String] The signer EID to notify
      # @return [Boolean] true if notification was sent
      def notify_signer(packet_eid:, signer_eid:, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: notify_signer_mutation,
                                 variables: {
                                   eid: packet_eid,
                                   signerEid: signer_eid
                                 }
                               })

        data = response.data
        raise APIError, "Failed to notify signer: #{data[:errors]}" unless data[:data] && data[:data][:notifySigner]

        data[:data][:notifySigner][:ok] || true
      end

      # Void a document group (cancel signed documents)
      #
      # @param eid [String] The packet EID
      # @param reason [String] Reason for voiding (optional)
      # @return [Boolean] true if voiding was successful
      def void_document_group(eid:, reason: nil, client: nil)
        client ||= self.client

        variables = { eid: eid }
        variables[:reason] = reason if reason

        response = client.post('https://graphql.useanvil.com/', {
                                 query: void_document_group_mutation,
                                 variables: variables
                               })

        data = response.data
        unless data[:data] && data[:data][:voidDocumentGroup]
          raise APIError, "Failed to void document group: #{data[:errors]}"
        end

        data[:data][:voidDocumentGroup][:ok] || true
      end

      # Expire all active signing tokens for a packet
      #
      # @param eid [String] The packet EID
      # @return [Boolean] true if tokens were expired
      def expire_signer_tokens(eid:, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: expire_signer_tokens_mutation,
                                 variables: { eid: eid }
                               })

        data = response.data
        unless data[:data] && data[:data][:expireSignerTokens]
          raise APIError, "Failed to expire signer tokens: #{data[:errors]}"
        end

        data[:data][:expireSignerTokens][:ok] || true
      end

      private

      def build_create_payload(name, signers, files, options)
        payload = {
          name: name,
          signers: build_signers_payload(signers)
        }

        payload[:files] = build_files_payload(files) if files
        payload[:isDraft] = options[:is_draft] if options.key?(:is_draft)
        payload[:webhookURL] = options[:webhook_url] if options[:webhook_url]
        payload[:signatureEmailSubject] = options[:email_subject] if options[:email_subject]
        payload[:signatureEmailBody] = options[:email_body] if options[:email_body]

        payload
      end

      def build_signers_payload(signers)
        signers.map do |signer|
          {
            name: signer[:name],
            email: signer[:email],
            role: signer[:role] || 'signer',
            signerType: signer[:signer_type] || 'email'
          }.compact
        end
      end

      def build_files_payload(files)
        files.map do |file|
          if file[:type] == :pdf && file[:id]
            # Template ID should be castEid
            {
              id: 'file1', # File identifier
              castEid: file[:id] # Template ID
            }
          elsif file[:type] == :upload && file[:data]
            {
              type: 'upload',
              data: Base64.strict_encode64(file[:data]),
              filename: file[:filename] || 'document.pdf'
            }
          else
            file
          end
        end
      end

      # GraphQL queries and mutations (simplified versions)
      def create_packet_mutation
        <<~GRAPHQL
          mutation CreateEtchPacket($input: JSON) {
            createEtchPacket(variables: $input) {
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
      end

      def find_packet_query
        <<~GRAPHQL
          query GetEtchPacket($eid: String!) {
            etchPacket(eid: $eid) {
              eid
              name
              status
              createdAt
              completedAt
              signers {
                eid
                name
                email
                status
                completedAt
              }
              documents {
                eid
                name
                type
              }
            }
          }
        GRAPHQL
      end

      def list_packets_query
        <<~GRAPHQL
          query ListEtchPackets($limit: Int, $offset: Int, $status: String) {
            etchPackets(limit: $limit, offset: $offset, status: $status) {
              eid
              name
              status
              createdAt
              completedAt
            }
          }
        GRAPHQL
      end

      def generate_url_mutation
        <<~GRAPHQL
          mutation GenerateEtchSignURL($input: GenerateEtchSignURLInput!) {
            generateEtchSignURL(input: $input) {
              url
            }
          }
        GRAPHQL
      end

      def update_packet_mutation
        <<~GRAPHQL
          mutation UpdateEtchPacket($input: JSON) {
            updateEtchPacket(variables: $input) {
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
      end

      def send_packet_mutation
        <<~GRAPHQL
          mutation SendEtchPacket($input: JSON) {
            sendEtchPacket(variables: $input) {
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
      end

      def delete_packet_mutation
        <<~GRAPHQL
          mutation RemoveEtchPacket($eid: String!) {
            removeEtchPacket(eid: $eid) {
              ok
            }
          }
        GRAPHQL
      end

      def skip_signer_mutation
        <<~GRAPHQL
          mutation SkipSigner($eid: String!, $signerEid: String!) {
            skipSigner(eid: $eid, signerEid: $signerEid) {
              eid
              name
              status
              signers {
                eid
                name
                email
                status
              }
            }
          }
        GRAPHQL
      end

      def notify_signer_mutation
        <<~GRAPHQL
          mutation NotifySigner($eid: String!, $signerEid: String!) {
            notifySigner(eid: $eid, signerEid: $signerEid) {
              ok
            }
          }
        GRAPHQL
      end

      def void_document_group_mutation
        <<~GRAPHQL
          mutation VoidDocumentGroup($eid: String!, $reason: String) {
            voidDocumentGroup(eid: $eid, reason: $reason) {
              ok
            }
          }
        GRAPHQL
      end

      def expire_signer_tokens_mutation
        <<~GRAPHQL
          mutation ExpireSignerTokens($eid: String!) {
            expireSignerTokens(eid: $eid) {
              ok
            }
          }
        GRAPHQL
      end
    end
  end

  # Helper class for signature signers
  class SignatureSigner < Resources::Base
    attr_reader :packet

    def initialize(attributes, packet: nil)
      super(attributes)
      @packet = packet
    end

    def eid
      attributes[:eid]
    end

    def name
      attributes[:name]
    end

    def email
      attributes[:email]
    end

    def status
      attributes[:status]
    end

    def complete?
      status == 'complete'
    end

    def completed_at
      return unless attributes[:completed_at]

      Time.parse(attributes[:completed_at])
    end

    # Get signing URL for this signer
    def signing_url(client_user_id: nil)
      return nil unless packet

      packet.signing_url(
        signer_id: eid,
        client_user_id: client_user_id
      )
    end

    # Skip this signer in the signature flow
    def skip!
      return nil unless packet

      packet.skip_signer(eid)
    end

    # Send a reminder notification to this signer
    def send_reminder!
      return nil unless packet

      packet.notify_signer(eid)
    end
  end
end
