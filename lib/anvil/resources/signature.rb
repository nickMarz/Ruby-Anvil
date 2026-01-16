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
        if data[:data] && data[:data][:createEtchPacket]
          new(data[:data][:createEtchPacket], client: client)
        else
          raise APIError, "Failed to create signature packet: #{data[:errors]}"
        end
      end

      # Find a signature packet by ID
      def find(packet_eid, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
          query: find_packet_query,
          variables: { eid: packet_eid }
        })

        data = response.data
        if data[:data] && data[:data][:etchPacket]
          new(data[:data][:etchPacket], client: client)
        else
          raise NotFoundError, "Signature packet not found: #{packet_eid}"
        end
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
        if data[:data] && data[:data][:generateEtchSignURL]
          data[:data][:generateEtchSignURL][:url]
        else
          raise APIError, "Failed to generate signing URL"
        end
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
              id: 'file1',  # File identifier
              castEid: file[:id]  # Template ID
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
      if attributes[:completed_at]
        Time.parse(attributes[:completed_at])
      end
    end

    # Get signing URL for this signer
    def signing_url(client_user_id: nil)
      return nil unless packet

      packet.signing_url(
        signer_id: eid,
        client_user_id: client_user_id
      )
    end
  end
end