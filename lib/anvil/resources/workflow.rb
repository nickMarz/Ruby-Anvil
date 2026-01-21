# frozen_string_literal: true

module Anvil
  class Workflow < Resources::Base
    # Workflow statuses
    STATUSES = %w[draft published].freeze

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

    # Check workflow status
    def draft?
      status == 'draft'
    end

    def published?
      status == 'published'
    end

    # Get workflow steps
    def steps
      Array(attributes[:steps])
    end

    # Get workflow forges (forms)
    def forges
      Array(attributes[:forges])
    end

    # Get workflow casts (PDF templates)
    def casts
      Array(attributes[:casts])
    end

    # Reload from API
    def reload!
      refreshed = self.class.find(eid, client: client)
      @attributes = refreshed.attributes
      self
    end

    # Start workflow with initial data
    #
    # @param data [Hash] Initial workflow data
    # @return [WorkflowSubmission] The workflow submission
    def start(data:)
      self.class.start_workflow(
        weld_eid: eid,
        data: data,
        client: client
      )
    end

    # Get all submissions for this workflow
    #
    # @param options [Hash] Query options
    # @return [Array<WorkflowSubmission>] List of submissions
    def submissions(**options)
      self.class.get_submissions(
        weld_eid: eid,
        client: client,
        **options
      )
    end

    class << self
      # Create a new workflow
      #
      # @param name [String] Name of the workflow
      # @param forges [Array<String>] Array of forge (form) EIDs
      # @param casts [Array<String>] Array of cast (template) EIDs
      # @param options [Hash] Additional options
      # @return [Workflow] The created workflow
      def create(name:, forges: [], casts: [], **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = {
          name: name,
          forges: forges,
          casts: casts
        }
        payload[:steps] = options[:steps] if options[:steps]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: create_workflow_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        raise APIError, "Failed to create workflow: #{data[:errors]}" unless data[:data] && data[:data][:createWeld]

        new(data[:data][:createWeld], client: client)
      end

      # Find a workflow by ID
      def find(weld_eid, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: find_workflow_query,
                                 variables: { eid: weld_eid }
                               })

        data = response.data
        raise NotFoundError, "Workflow not found: #{weld_eid}" unless data[:data] && data[:data][:weld]

        new(data[:data][:weld], client: client)
      end

      # Start a workflow with initial data
      #
      # @param weld_eid [String] The workflow EID
      # @param data [Hash] Initial workflow data
      # @return [WorkflowSubmission] The workflow submission
      def start_workflow(weld_eid:, data:, client: nil)
        client ||= self.client

        payload = {
          weldEid: weld_eid,
          data: data
        }

        response = client.post('https://graphql.useanvil.com/', {
                                 query: start_workflow_mutation,
                                 variables: { input: payload }
                               })

        response_data = response.data
        unless response_data[:data] && response_data[:data][:startWeld]
          raise APIError, "Failed to start workflow: #{response_data[:errors]}"
        end

        WorkflowSubmission.new(response_data[:data][:startWeld], client: client)
      end

      # Get submissions for a workflow
      #
      # @param weld_eid [String] The workflow EID
      # @param options [Hash] Query options
      # @return [Array<WorkflowSubmission>] List of submissions
      def get_submissions(weld_eid:, client: nil, **options)
        client ||= self.client

        variables = { weldEid: weld_eid }
        variables[:status] = options[:status] if options[:status]
        variables[:limit] = options[:limit] if options[:limit]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: workflow_submissions_query,
                                 variables: variables
                               })

        data = response.data
        if data[:data] && data[:data][:weldSubmissions]
          data[:data][:weldSubmissions].map { |sub| WorkflowSubmission.new(sub, client: client) }
        else
          []
        end
      end

      private

      def create_workflow_mutation
        <<~GRAPHQL
          mutation CreateWeld($input: JSON) {
            createWeld(variables: $input) {
              eid
              name
              status
              forges
              casts
              steps
              createdAt
            }
          }
        GRAPHQL
      end

      def find_workflow_query
        <<~GRAPHQL
          query GetWeld($eid: String!) {
            weld(eid: $eid) {
              eid
              name
              status
              forges
              casts
              steps
              createdAt
              updatedAt
            }
          }
        GRAPHQL
      end

      def start_workflow_mutation
        <<~GRAPHQL
          mutation StartWeld($input: JSON) {
            startWeld(variables: $input) {
              eid
              weldEid
              status
              currentStep
              completedSteps
              data
              createdAt
            }
          }
        GRAPHQL
      end

      def workflow_submissions_query
        <<~GRAPHQL
          query WeldSubmissions($weldEid: String!, $status: String, $limit: Int) {
            weldSubmissions(weldEid: $weldEid, status: $status, limit: $limit) {
              eid
              weldEid
              status
              currentStep
              completedSteps
              data
              createdAt
              updatedAt
            }
          }
        GRAPHQL
      end
    end
  end

  # Helper class for workflow submissions
  class WorkflowSubmission < Resources::Base
    def eid
      attributes[:eid]
    end

    def weld_eid
      attributes[:weldEid] || attributes[:weld_eid]
    end

    def status
      attributes[:status]
    end

    def current_step
      attributes[:currentStep] || attributes[:current_step]
    end

    def completed_steps
      Array(attributes[:completedSteps] || attributes[:completed_steps])
    end

    def data
      attributes[:data] || {}
    end

    def created_at
      return unless attributes[:createdAt] || attributes[:created_at]

      Time.parse(attributes[:createdAt] || attributes[:created_at])
    end

    # Check submission status
    def in_progress?
      status == 'in_progress'
    end

    def complete?
      status == 'complete'
    end

    # Continue a workflow submission with new data
    #
    # @param step_id [String] The step ID to continue from
    # @param data [Hash] Additional data for the step
    # @return [WorkflowSubmission] The updated submission
    def continue(step_id:, data:)
      response = client.post('https://graphql.useanvil.com/', {
                               query: continue_workflow_mutation,
                               variables: {
                                 eid: eid,
                                 stepId: step_id,
                                 data: data
                               }
                             })

      response_data = response.data
      unless response_data[:data] && response_data[:data][:continueWeld]
        raise APIError, "Failed to continue workflow: #{response_data[:errors]}"
      end

      @attributes = response_data[:data][:continueWeld]
      self
    end

    private

    def continue_workflow_mutation
      <<~GRAPHQL
        mutation ContinueWeld($eid: String!, $stepId: String!, $data: JSON) {
          continueWeld(eid: $eid, stepId: $stepId, data: $data) {
            eid
            weldEid
            status
            currentStep
            completedSteps
            data
            updatedAt
          }
        }
      GRAPHQL
    end
  end
end
