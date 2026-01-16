# frozen_string_literal: true

module Anvil
  module Resources
    class Base
      attr_reader :attributes, :client

      def initialize(attributes = {}, client: nil)
        @attributes = symbolize_keys(attributes)
        @client = client || default_client
      end

      # ActiveRecord-like attribute accessors
      def method_missing(method_name, *args)
        if method_name.to_s.end_with?('=')
          attribute = method_name.to_s.chomp('=').to_sym
          attributes[attribute] = args.first
        elsif attributes.key?(method_name)
          attributes[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.end_with?('=') || attributes.key?(method_name) || super
      end

      def to_h
        attributes
      end

      def to_json(*args)
        attributes.to_json(*args)
      end

      def inspect
        "#<#{self.class.name} #{attributes.inspect}>"
      end

      def ==(other)
        other.is_a?(self.class) && attributes == other.attributes
      end

      protected

      def default_client
        @default_client ||= Client.new
      end

      def symbolize_keys(hash)
        return {} unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          sym_key = key.is_a?(String) ? key.to_sym : key
          result[sym_key] = value.is_a?(Hash) ? symbolize_keys(value) : value
        end
      end

      class << self
        def client
          @client ||= Client.new
        end

        attr_writer :client

        # Override in subclasses to provide resource-specific client
        def with_client(api_key: nil)
          original_client = @client
          @client = Client.new(api_key: api_key)
          yield
        ensure
          @client = original_client
        end

        # Helper for building resource instances from API responses
        def build_from_response(response)
          if response.data.is_a?(Array)
            response.data.map { |item| new(item) }
          else
            new(response.data)
          end
        end

        # Common API operations
        def find(id, client: nil)
          raise NotImplementedError, "#{self.class.name}#find must be implemented by subclass"
        end

        def create(attributes = {}, client: nil)
          raise NotImplementedError, "#{self.class.name}#create must be implemented by subclass"
        end

        def list(params = {}, client: nil)
          raise NotImplementedError, "#{self.class.name}#list must be implemented by subclass"
        end
      end
    end
  end
end
