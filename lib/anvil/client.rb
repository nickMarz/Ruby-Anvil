# frozen_string_literal: true

require 'net/http/post/multipart' rescue LoadError

module Anvil
  class Client
    attr_reader :config, :rate_limiter

    def initialize(api_key: nil, config: nil)
      @config = config || Anvil.configuration.dup
      @config.api_key = api_key if api_key
      @config.validate!
      @rate_limiter = RateLimiter.new
    end

    def get(path, params = {}, options = {})
      request(:get, path, params: params, **options)
    end

    def post(path, data = {}, options = {})
      request(:post, path, body: data, **options)
    end

    def put(path, data = {}, options = {})
      request(:put, path, body: data, **options)
    end

    def delete(path, params = {}, options = {})
      request(:delete, path, params: params, **options)
    end

    private

    def request(method, path, params: nil, body: nil, headers: {}, **options)
      uri = build_uri(path, params)

      rate_limiter.with_retry do
        http = build_http(uri)
        request = build_request(method, uri, body, headers)

        response = http.request(request)
        wrapped_response = Response.new(response)

        handle_response(wrapped_response)
      end
    end

    def build_uri(path, params)
      uri = URI.parse(path.start_with?('http') ? path : "#{config.base_url}#{path}")

      if params && !params.empty?
        uri.query = URI.encode_www_form(params)
      end

      uri
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = config.open_timeout
      http.read_timeout = config.timeout

      # Debug output in development
      if config.development?
        http.set_debug_output($stdout)
      end

      http
    end

    def build_request(method, uri, body, headers)
      klass = case method.to_sym
              when :get    then Net::HTTP::Get
              when :post   then Net::HTTP::Post
              when :put    then Net::HTTP::Put
              when :delete then Net::HTTP::Delete
              else
                raise ArgumentError, "Unsupported HTTP method: #{method}"
              end

      request = klass.new(uri.request_uri)

      # Set authentication
      request.basic_auth(config.api_key, '')

      # Set headers
      default_headers.merge(headers).each do |key, value|
        request[key] = value
      end

      # Set body
      if body
        if body.is_a?(Hash)
          request['Content-Type'] = 'application/json'
          request.body = JSON.generate(body)
        elsif body.is_a?(String)
          request.body = body
        end
      end

      request
    end

    def default_headers
      {
        'User-Agent' => "Anvil Ruby/#{Anvil::VERSION}",
        'Accept' => 'application/json'
      }
    end

    def handle_response(response)
      return response if response.success?

      case response.code
      when 400
        raise ValidationError.new(response.error_message, response)
      when 401
        raise AuthenticationError.new(
          'Invalid API key. Check your API key at https://app.useanvil.com',
          response
        )
      when 404
        raise NotFoundError.new(response.error_message, response)
      when 429
        # This should be handled by rate_limiter, but just in case
        raise RateLimitError.new('Rate limit exceeded', response)
      when 500..599
        raise ServerError.new(
          "Server error: #{response.error_message}",
          response
        )
      else
        raise APIError.new(response.error_message, response)
      end
    end

    # Special method for multipart uploads (requires multipart-post gem as optional dependency)
    def post_multipart(path, params = {}, files = {})
      unless defined?(Net::HTTP::Post::Multipart)
        raise LoadError, "multipart-post gem is required for file uploads. Add it to your Gemfile."
      end

      uri = build_uri(path, nil)

      # Convert files to UploadIO objects
      upload_params = params.dup
      files.each do |key, file|
        if file.respond_to?(:read)
          upload_params[key] = UploadIO.new(
            file,
            'application/octet-stream',
            File.basename(file.path)
          )
        end
      end

      rate_limiter.with_retry do
        http = build_http(uri)
        request = Net::HTTP::Post::Multipart.new(uri.path, upload_params)
        request.basic_auth(config.api_key, '')

        response = http.request(request)
        wrapped_response = Response.new(response)

        handle_response(wrapped_response)
      end
    end
  end
end