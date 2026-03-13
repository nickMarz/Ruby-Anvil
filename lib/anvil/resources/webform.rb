# frozen_string_literal: true

module Anvil
  class Webform < Resources::Base
    def id
      attributes[:eid] || attributes[:id]
    end

    def eid
      attributes[:eid]
    end

    def name
      attributes[:name]
    end

    def slug
      attributes[:slug]
    end

    def fields
      Array(attributes[:fields])
    end

    # Submit data to this webform
    #
    # @param data [Hash] The form data to submit
    # @return [Hash] The submission result
    def submit(data: {})
      result = client.graphql(self.class.send(:create_submission_mutation), variables: {
                                forgeEid: eid,
                                input: data
                              })
      raise APIError, "Failed to submit form data: #{eid}" unless result && result[:createSubmission]

      result[:createSubmission]
    end

    # Get submissions for this webform
    #
    # @param limit [Integer] Number of submissions to return
    # @param offset [Integer] Offset for pagination
    # @return [Array<Hash>] The form submissions
    def submissions(limit: 10, offset: 0)
      result = client.graphql(self.class.send(:submissions_query), variables: {
                                forgeEid: eid,
                                limit: limit,
                                offset: offset
                              })

      if result && result[:forgeSubmissions]
        Array(result[:forgeSubmissions])
      else
        []
      end
    end

    # Reload from API
    def reload!
      refreshed = self.class.find(eid, client: client)
      @attributes = refreshed.attributes
      self
    end

    class << self
      # Create a new webform
      #
      # @param name [String] Name of the form
      # @param fields [Array<Hash>] Form field definitions
      # @param options [Hash] Additional options
      # @return [Webform] The created webform
      def create(name:, fields: [], **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = { name: name, fields: fields }
        payload[:slug] = options[:slug] if options[:slug]

        result = client.graphql(create_forge_mutation, variables: { input: payload })
        raise APIError, "Failed to create webform: #{result}" unless result && result[:createForge]

        new(result[:createForge], client: client)
      end

      # Find a webform by EID
      #
      # @param form_eid [String] The webform EID
      # @param client [Client] Optional client instance
      # @return [Webform] The webform
      def find(form_eid, client: nil)
        client ||= self.client

        result = client.graphql(forge_query, variables: { eid: form_eid })
        raise NotFoundError, "Webform not found: #{form_eid}" unless result && result[:forge]

        new(result[:forge], client: client)
      end

      private

      def create_forge_mutation
        <<~GRAPHQL
          mutation CreateForge($input: JSON) {
            createForge(variables: $input) {
              eid
              name
              slug
              fields
              createdAt
            }
          }
        GRAPHQL
      end

      def forge_query
        <<~GRAPHQL
          query GetForge($eid: String!) {
            forge(eid: $eid) {
              eid
              name
              slug
              fields
              createdAt
            }
          }
        GRAPHQL
      end

      def create_submission_mutation
        <<~GRAPHQL
          mutation CreateSubmission($forgeEid: String!, $input: JSON) {
            createSubmission(forgeEid: $forgeEid, variables: $input) {
              eid
              data
              createdAt
            }
          }
        GRAPHQL
      end

      def submissions_query
        <<~GRAPHQL
          query GetForgeSubmissions($forgeEid: String!, $limit: Int, $offset: Int) {
            forgeSubmissions(forgeEid: $forgeEid, limit: $limit, offset: $offset) {
              eid
              data
              createdAt
            }
          }
        GRAPHQL
      end
    end
  end
end
