# frozen_string_literal: true

module Anvil
  class Webform < Resources::Base
    # Webform field types
    FIELD_TYPES = %w[
      text email phone number
      textarea select multiselect
      checkbox radio
      date time datetime
      file
    ].freeze

    def id
      attributes[:eid] || attributes[:id]
    end

    def eid
      attributes[:eid]
    end

    def name
      attributes[:name]
    end

    # Get form fields
    def fields
      Array(attributes[:fields])
    end

    # Get form styling configuration
    def styling
      attributes[:styling] || {}
    end

    # Get validation rules
    def validation_rules
      attributes[:validationRules] || attributes[:validation_rules] || {}
    end

    # Reload from API
    def reload!
      refreshed = self.class.find(eid, client: client)
      @attributes = refreshed.attributes
      self
    end

    # Submit form data
    #
    # @param data [Hash] Form data to submit
    # @param files [Hash] File uploads (optional)
    # @return [WebformSubmission] The form submission
    def submit(data:, files: {})
      self.class.create_submission(
        forge_eid: eid,
        data: data,
        files: files,
        client: client
      )
    end

    # Get all submissions for this form
    #
    # @param options [Hash] Query options
    # @return [Array<WebformSubmission>] List of submissions
    def submissions(**options)
      self.class.get_submissions(
        forge_eid: eid,
        client: client,
        **options
      )
    end

    # Export submissions
    #
    # @param format [Symbol] Export format (:csv, :json)
    # @return [String] Exported data
    def export_submissions(format: :csv)
      self.class.export_submissions(
        forge_eid: eid,
        format: format,
        client: client
      )
    end

    class << self
      # Create a new webform
      #
      # @param name [String] Name of the webform
      # @param fields [Array<Hash>] Form field definitions
      # @param options [Hash] Additional options
      # @return [Webform] The created webform
      def create(name:, fields:, **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = {
          name: name,
          fields: normalize_fields(fields)
        }
        payload[:styling] = options[:styling] if options[:styling]
        payload[:validationRules] = options[:validation_rules] if options[:validation_rules]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: create_webform_mutation,
                                 variables: { input: payload }
                               })

        data = response.data
        unless data[:data] && data[:data][:createForge]
          raise APIError, "Failed to create webform: #{data[:errors]}"
        end

        new(data[:data][:createForge], client: client)
      end

      # Find a webform by ID
      def find(forge_eid, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: find_webform_query,
                                 variables: { eid: forge_eid }
                               })

        data = response.data
        raise NotFoundError, "Webform not found: #{forge_eid}" unless data[:data] && data[:data][:forge]

        new(data[:data][:forge], client: client)
      end

      # Create a form submission
      #
      # @param forge_eid [String] The webform EID
      # @param data [Hash] Form data
      # @param files [Hash] File uploads (optional)
      # @return [WebformSubmission] The form submission
      def create_submission(forge_eid:, data:, files: {}, client: nil)
        client ||= self.client

        payload = {
          forgeEid: forge_eid,
          data: data
        }

        # Handle file uploads by converting to base64
        unless files.empty?
          payload[:files] = files.transform_values do |file|
            if file.respond_to?(:read)
              Base64.strict_encode64(file.read)
            else
              file
            end
          end
        end

        response = client.post('https://graphql.useanvil.com/', {
                                 query: create_submission_mutation,
                                 variables: { input: payload }
                               })

        response_data = response.data
        unless response_data[:data] && response_data[:data][:createSubmission]
          raise APIError, "Failed to create submission: #{response_data[:errors]}"
        end

        WebformSubmission.new(response_data[:data][:createSubmission], client: client)
      end

      # Get submissions for a webform
      #
      # @param forge_eid [String] The webform EID
      # @param options [Hash] Query options
      # @return [Array<WebformSubmission>] List of submissions
      def get_submissions(forge_eid:, client: nil, **options)
        client ||= self.client

        variables = { forgeEid: forge_eid }
        variables[:from] = options[:from].iso8601 if options[:from]
        variables[:to] = options[:to].iso8601 if options[:to]
        variables[:limit] = options[:limit] if options[:limit]

        response = client.post('https://graphql.useanvil.com/', {
                                 query: webform_submissions_query,
                                 variables: variables
                               })

        data = response.data
        if data[:data] && data[:data][:forgeSubmissions]
          data[:data][:forgeSubmissions].map { |sub| WebformSubmission.new(sub, client: client) }
        else
          []
        end
      end

      # Export webform submissions
      #
      # @param forge_eid [String] The webform EID
      # @param format [Symbol] Export format (:csv, :json)
      # @return [String] Exported data
      def export_submissions(forge_eid:, format: :csv, client: nil)
        client ||= self.client

        response = client.post('https://graphql.useanvil.com/', {
                                 query: export_submissions_query,
                                 variables: {
                                   forgeEid: forge_eid,
                                   format: format.to_s.upcase
                                 }
                               })

        data = response.data
        unless data[:data] && data[:data][:exportForgeSubmissions]
          raise APIError, "Failed to export submissions: #{data[:errors]}"
        end

        data[:data][:exportForgeSubmissions][:data]
      end

      private

      # Normalize field definitions
      def normalize_fields(fields)
        fields.map do |field|
          {
            type: field[:type],
            name: field[:name],
            label: field[:label],
            required: field[:required] || false,
            options: field[:options],
            validation: field[:validation]
          }.compact
        end
      end

      def create_webform_mutation
        <<~GRAPHQL
          mutation CreateForge($input: JSON) {
            createForge(variables: $input) {
              eid
              name
              fields
              styling
              validationRules
              createdAt
            }
          }
        GRAPHQL
      end

      def find_webform_query
        <<~GRAPHQL
          query GetForge($eid: String!) {
            forge(eid: $eid) {
              eid
              name
              fields
              styling
              validationRules
              createdAt
              updatedAt
            }
          }
        GRAPHQL
      end

      def create_submission_mutation
        <<~GRAPHQL
          mutation CreateSubmission($input: JSON) {
            createSubmission(variables: $input) {
              eid
              forgeEid
              data
              submittedAt
              createdAt
            }
          }
        GRAPHQL
      end

      def webform_submissions_query
        <<~GRAPHQL
          query ForgeSubmissions($forgeEid: String!, $from: String, $to: String, $limit: Int) {
            forgeSubmissions(forgeEid: $forgeEid, from: $from, to: $to, limit: $limit) {
              eid
              forgeEid
              data
              submittedAt
              createdAt
            }
          }
        GRAPHQL
      end

      def export_submissions_query
        <<~GRAPHQL
          query ExportForgeSubmissions($forgeEid: String!, $format: String!) {
            exportForgeSubmissions(forgeEid: $forgeEid, format: $format) {
              data
            }
          }
        GRAPHQL
      end
    end
  end

  # Helper class for webform submissions
  class WebformSubmission < Resources::Base
    def eid
      attributes[:eid]
    end

    def forge_eid
      attributes[:forgeEid] || attributes[:forge_eid]
    end

    def data
      attributes[:data] || {}
    end

    def submitted_at
      return unless attributes[:submittedAt] || attributes[:submitted_at]

      Time.parse(attributes[:submittedAt] || attributes[:submitted_at])
    end

    def created_at
      return unless attributes[:createdAt] || attributes[:created_at]

      Time.parse(attributes[:createdAt] || attributes[:created_at])
    end
  end
end
