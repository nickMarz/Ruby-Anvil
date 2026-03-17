# frozen_string_literal: true

module Anvil
  class Workflow < Resources::Base
    def id
      attributes[:eid] || attributes[:id]
    end

    def eid
      attributes[:eid]
    end

    def name
      attributes[:name]
    end

    def status
      attributes[:status]
    end

    def slug
      attributes[:slug]
    end

    def published?
      status == 'published'
    end

    def draft?
      status == 'draft'
    end

    # Start the workflow with initial data
    #
    # @param data [Hash] The data to start the workflow with
    # @return [Hash] The submission data
    def start(data: {})
      result = client.graphql(self.class.send(:create_weld_data_mutation), variables: {
                                eid: eid,
                                input: data
                              })
      raise APIError, "Failed to start workflow: #{eid}" unless result && result[:createWeldData]

      result[:createWeldData]
    end

    # Get submissions for this workflow
    #
    # @param limit [Integer] Number of submissions to return
    # @param offset [Integer] Offset for pagination
    # @return [Array<Hash>] The workflow submissions
    def submissions(limit: 10, offset: 0)
      result = client.graphql(self.class.send(:weld_data_query), variables: {
                                eid: eid,
                                limit: limit,
                                offset: offset
                              })

      if result && result[:weldData]
        Array(result[:weldData])
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
      # Create a new workflow
      #
      # @param name [String] Name of the workflow
      # @param options [Hash] Additional options (forges, casts, slug)
      # @return [Workflow] The created workflow
      def create(name:, **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = { name: name }
        payload[:slug] = options[:slug] if options[:slug]
        payload[:forges] = options[:forges] if options[:forges]
        payload[:casts] = options[:casts] if options[:casts]

        result = client.graphql(create_weld_mutation, variables: { input: payload })
        raise APIError, "Failed to create workflow: #{result}" unless result && result[:createWeld]

        new(result[:createWeld], client: client)
      end

      # Find a workflow by EID
      #
      # @param workflow_eid [String] The workflow EID
      # @param client [Client] Optional client instance
      # @return [Workflow] The workflow
      def find(workflow_eid, client: nil)
        client ||= self.client

        result = client.graphql(weld_query, variables: { eid: workflow_eid })
        raise NotFoundError, "Workflow not found: #{workflow_eid}" unless result && result[:weld]

        new(result[:weld], client: client)
      end

      private

      def create_weld_mutation
        <<~GRAPHQL
          mutation CreateWeld($input: JSON) {
            createWeld(variables: $input) {
              eid
              name
              slug
              status
              createdAt
            }
          }
        GRAPHQL
      end

      def weld_query
        <<~GRAPHQL
          query GetWeld($eid: String!) {
            weld(eid: $eid) {
              eid
              name
              slug
              status
              createdAt
              forges {
                eid
                name
              }
            }
          }
        GRAPHQL
      end

      def create_weld_data_mutation
        <<~GRAPHQL
          mutation CreateWeldData($eid: String!, $input: JSON) {
            createWeldData(weldEid: $eid, variables: $input) {
              eid
              status
              createdAt
              data
            }
          }
        GRAPHQL
      end

      def weld_data_query
        <<~GRAPHQL
          query GetWeldData($eid: String!, $limit: Int, $offset: Int) {
            weldData(weldEid: $eid, limit: $limit, offset: $offset) {
              eid
              status
              createdAt
              data
            }
          }
        GRAPHQL
      end
    end
  end
end
