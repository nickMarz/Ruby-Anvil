#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil/env_loader'

puts 'Before loading .env:'
puts "ANVIL_API_KEY = #{ENV['ANVIL_API_KEY'].inspect}"

path = File.expand_path('.env', __dir__)
puts "\nLoading from: #{path}"
puts "File exists? #{File.exist?(path)}"

if File.exist?(path)
  puts "\n.env contents:"
  File.readlines(path).each_with_index do |line, i|
    puts "  Line #{i + 1}: #{line.inspect}"
    if line =~ /\A([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\z/
      puts "    -> Matched! Key: #{Regexp.last_match(1)}, Value: #{Regexp.last_match(2)[0..20]}..."
    end
  end
end

puts "\nCalling Anvil::EnvLoader.load..."
Anvil::EnvLoader.load(path)

puts "\nAfter loading .env:"
puts "ANVIL_API_KEY = #{ENV['ANVIL_API_KEY'] ? "#{ENV['ANVIL_API_KEY'][0..15]}..." : 'NOT SET'}"
