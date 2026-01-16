# frozen_string_literal: true

module Anvil
  # Simple .env file loader (no dependencies required!)
  class EnvLoader
    def self.load(path = '.env')
      return unless File.exist?(path)

      File.readlines(path).each do |line|
        line = line.chomp # Remove newline

        # Skip comments and empty lines
        next if line.strip.empty? || line.strip.start_with?('#')

        # Parse KEY=value format
        next unless line =~ /\A([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\z/

        key = ::Regexp.last_match(1)
        value = ::Regexp.last_match(2).strip

        # Remove quotes if present
        value = value[1..-2] if (value.start_with?('"') && value.end_with?('"')) ||
                                (value.start_with?("'") && value.end_with?("'"))

        # Set environment variable
        ENV[key] = value
      end
    end
  end
end
