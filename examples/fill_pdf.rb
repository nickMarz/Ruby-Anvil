#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib to the load path if running directly
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'anvil'

# Example: Fill a PDF template with data
#
# This example demonstrates how to fill a PDF template with JSON data.
# You'll need:
# 1. An Anvil API key (set as ANVIL_API_KEY environment variable)
# 2. A PDF template ID from your Anvil account

# Configure Anvil (optional if using ENV var)
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.environment = :development # Use development for testing
end

# Template ID - replace with your actual template ID
TEMPLATE_ID = 'your_template_id_here'

# Sample data to fill the PDF
# Keys should match the field aliases in your PDF template
pdf_data = {
  # Basic fields
  name: 'John Doe',
  email: 'john.doe@example.com',
  phone: '(555) 123-4567',

  # Address
  address: '123 Main Street',
  city: 'San Francisco',
  state: 'CA',
  zip_code: '94102',

  # Date fields
  date: Date.today.strftime('%B %d, %Y'),

  # Checkboxes (use true/false)
  agree_to_terms: true,
  subscribe_newsletter: false,

  # Additional fields (customize based on your template)
  company: 'Acme Corp',
  position: 'Software Engineer',
  salary: '$120,000',
  start_date: '2024-02-01'
}

begin
  puts "Filling PDF template: #{TEMPLATE_ID}"
  puts "With data: #{pdf_data.keys.join(', ')}"

  # Fill the PDF
  pdf = Anvil::PDF.fill(
    template_id: TEMPLATE_ID,
    data: pdf_data,
    # Optional parameters
    title: 'Employment Agreement',
    font_size: 10,
    text_color: '#333333'
  )

  # Save the filled PDF
  filename = "filled_pdf_#{Time.now.to_i}.pdf"
  pdf.save_as(filename)

  puts "✅ PDF filled successfully!"
  puts "📄 Saved as: #{filename}"
  puts "📏 Size: #{pdf.size_human}"

  # You can also get the PDF as base64 for storing in a database
  # base64_pdf = pdf.to_base64
  # puts "Base64 length: #{base64_pdf.length}" if base64_pdf

rescue Anvil::ValidationError => e
  puts "❌ Validation error: #{e.message}"
  puts "Errors: #{e.errors.inspect}" if e.errors.any?
rescue Anvil::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check your API key"
rescue Anvil::Error => e
  puts "❌ Anvil error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end