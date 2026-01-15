#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test script for the Anvil gem

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'anvil'
require 'anvil/env_loader'

# Load .env file
Anvil::EnvLoader.load(File.expand_path('.env', __dir__))

# Configure Anvil (will use ANVIL_API_KEY from .env file)
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY'] || 'YOUR_API_KEY_HERE'
  config.environment = :development
end

puts "=" * 50
puts "Testing Anvil Ruby Gem"
puts "=" * 50

begin
  # Test 1: Generate a simple PDF from Markdown
  puts "\n📄 Generating PDF from Markdown..."

  pdf = Anvil::PDF.generate_from_markdown(<<~MD
    # Anvil Ruby Test

    This is a test of the Anvil Ruby gem!

    ## Features Working

    - ✅ API Configuration
    - ✅ PDF Generation
    - ✅ Zero dependencies

    Generated at: #{Time.now}
  MD
  )

  filename = "test_output_#{Time.now.to_i}.pdf"
  pdf.save_as(filename)

  puts "✅ Success! PDF saved as: #{filename}"
  puts "📏 Size: #{pdf.size_human}"

  # Test 2: Generate from HTML
  puts "\n📄 Generating PDF from HTML..."

  pdf2 = Anvil::PDF.generate_from_html(
    html: "<h1>Hello from Ruby!</h1><p>The Anvil gem is working!</p>",
    css: "h1 { color: #007bff; }",
    title: "Test PDF"
  )

  filename2 = "test_html_#{Time.now.to_i}.pdf"
  pdf2.save_as(filename2)

  puts "✅ Success! HTML PDF saved as: #{filename2}"
  puts "📏 Size: #{pdf2.size_human}"

  puts "\n🎉 All tests passed! Your Anvil Ruby gem is working!"

rescue Anvil::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check your API key above"
rescue Anvil::Error => e
  puts "❌ Anvil error: #{e.message}"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end