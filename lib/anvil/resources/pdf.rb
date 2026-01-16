# frozen_string_literal: true

module Anvil
  class PDF < Resources::Base
    attr_reader :raw_data

    def initialize(raw_data, attributes = {}, client: nil)
      super(attributes, client: client)
      @raw_data = raw_data
    end

    # Save the PDF to a file
    def save_as(filename, mode = 'wb')
      raise FileError, 'No PDF data to save' unless raw_data

      File.open(filename, mode) do |file|
        file.write(raw_data)
      end
      filename
    end

    # Save and raise on error
    def save_as!(filename, mode = 'wb')
      save_as(filename, mode)
    rescue StandardError => e
      raise FileError, "Failed to save PDF: #{e.message}"
    end

    # Get the PDF as a base64 encoded string
    def to_base64
      return nil unless raw_data

      Base64.strict_encode64(raw_data)
    end

    # Get the size in bytes
    def size
      raw_data&.bytesize || 0
    end

    def size_human
      size_in_bytes = size
      return '0 B' if size_in_bytes.zero?

      units = %w[B KB MB GB]
      exp = (Math.log(size_in_bytes) / Math.log(1024)).to_i
      exp = units.size - 1 if exp >= units.size

      format('%.2f %s', size_in_bytes.to_f / (1024**exp), units[exp])
    end

    class << self
      # Fill a PDF template with data
      #
      # @param template_id [String] The PDF template ID
      # @param data [Hash] The data to fill the PDF with
      # @param options [Hash] Additional options
      # @option options [String] :title Optional document title
      # @option options [String] :font_family Font family (default: "Noto Sans")
      # @option options [Integer] :font_size Font size (default: 10)
      # @option options [String] :text_color Text color (default: "#333333")
      # @option options [Boolean] :use_interactive_fields Use interactive form fields
      # @option options [String] :api_key Optional API key override
      # @return [PDF] The filled PDF
      def fill(template_id:, data:, **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        payload = build_fill_payload(data, options)
        path = "/fill/#{template_id}.pdf"

        response = client.post(path, payload)

        raise APIError, "Expected PDF response but got: #{response.content_type}" unless response.binary?

        new(response.raw_body, { template_id: template_id }, client: client)
      end

      # Generate a PDF from HTML or Markdown
      #
      # @param type [Symbol, String] :html or :markdown
      # @param data [Hash, Array] Content data
      # @param options [Hash] Additional options
      # @option options [String] :title Document title
      # @option options [Hash] :page Page configuration
      # @option options [String] :api_key Optional API key override
      # @return [PDF] The generated PDF
      def generate(data:, type: :markdown, **options)
        api_key = options.delete(:api_key)
        client = api_key ? Client.new(api_key: api_key) : self.client

        type = type.to_s.downcase
        unless %w[html markdown].include?(type)
          raise ArgumentError, "Type must be :html or :markdown, got #{type.inspect}"
        end

        payload = build_generate_payload(type, data, options)
        path = '/generate-pdf'

        response = client.post(path, payload)

        raise APIError, "Expected PDF response but got: #{response.content_type}" unless response.binary?

        new(response.raw_body, { type: type }, client: client)
      end

      # Convenience methods for specific generation types
      def generate_from_html(html:, css: nil, **options)
        data = { html: html }
        data[:css] = css if css
        generate(type: :html, data: data, **options)
      end

      def generate_from_markdown(content, **options)
        data = if content.is_a?(String)
                 [{ content: content }]
               elsif content.is_a?(Array)
                 content
               else
                 raise ArgumentError, 'Markdown content must be a string or array'
               end

        generate(type: :markdown, data: data, **options)
      end

      private

      def build_fill_payload(data, options)
        payload = { data: data }

        # Add optional parameters if provided
        payload[:title] = options[:title] if options[:title]
        payload[:fontSize] = options[:font_size] if options[:font_size]
        payload[:fontFamily] = options[:font_family] if options[:font_family]
        payload[:textColor] = options[:text_color] if options[:text_color]
        payload[:useInteractiveFields] = options[:use_interactive_fields] if options.key?(:use_interactive_fields)

        payload
      end

      def build_generate_payload(type, data, options)
        payload = {
          type: type,
          data: data
        }

        # Add optional parameters
        payload[:title] = options[:title] if options[:title]

        # Page configuration
        if options[:page]
          page = options[:page]
          payload[:page] = {}
          payload[:page][:width] = page[:width] if page[:width]
          payload[:page][:height] = page[:height] if page[:height]
          payload[:page][:marginTop] = page[:margin_top] if page[:margin_top]
          payload[:page][:marginBottom] = page[:margin_bottom] if page[:margin_bottom]
          payload[:page][:marginLeft] = page[:margin_left] if page[:margin_left]
          payload[:page][:marginRight] = page[:margin_right] if page[:margin_right]
          payload[:page][:pageCount] = page[:page_count] if page.key?(:page_count)
        end

        payload
      end
    end
  end
end
