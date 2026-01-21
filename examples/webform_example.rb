#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating Webform (Forge) functionality in Anvil Ruby gem

require 'bundler/setup'
require 'anvil'
require 'anvil/env_loader'

# Load environment variables
Anvil::EnvLoader.load

# Configure Anvil
Anvil.configure do |config|
  config.api_key = ENV.fetch('ANVIL_API_KEY', nil)
  config.environment = :development
end

puts '=' * 60
puts 'Anvil Webform Examples'
puts '=' * 60
puts

# Example 1: Create a webform
puts '1. Create a webform'
puts '-' * 60

begin
  form = Anvil::Webform.create(
    name: 'Contact Form',
    fields: [
      {
        type: 'text',
        name: 'full_name',
        label: 'Full Name',
        required: true
      },
      {
        type: 'email',
        name: 'email',
        label: 'Email Address',
        required: true,
        validation: { format: 'email' }
      },
      {
        type: 'phone',
        name: 'phone',
        label: 'Phone Number',
        required: false
      },
      {
        type: 'select',
        name: 'department',
        label: 'Department',
        required: true,
        options: %w[Sales Support Engineering Marketing]
      },
      {
        type: 'textarea',
        name: 'message',
        label: 'Message',
        required: true
      }
    ],
    styling: {
      theme: 'modern',
      primary_color: '#007bff',
      font_family: 'Inter, sans-serif'
    }
  )

  puts "Created webform: #{form.name}"
  puts "Form EID: #{form.eid}"
  puts "Fields: #{form.fields.length}"
rescue Anvil::GraphQLError => e
  puts "GraphQL Error: #{e.message}"
rescue Anvil::Error => e
  puts "Error: #{e.message}"
end

puts
puts '=' * 60
puts

# Example 2: Get webform details
puts '2. Get webform details'
puts '-' * 60

if defined?(form) && form
  begin
    fetched_form = Anvil::Webform.find(form.eid)
    puts "Form: #{fetched_form.name}"
    puts "Fields: #{fetched_form.fields.length}"

    puts "\nField definitions:"
    fetched_form.fields.each do |field|
      puts "  - #{field[:label]} (#{field[:type]})#{' *required' if field[:required]}"
    end
  rescue Anvil::NotFoundError => e
    puts "Webform not found: #{e.message}"
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 3: Submit form data
puts '3. Submit form data'
puts '-' * 60

if defined?(form) && form
  begin
    submission = form.submit(
      data: {
        full_name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phone: '+1-555-0123',
        department: 'Engineering',
        message: "I'm interested in learning more about your API integration services."
      }
    )

    puts 'Form submitted successfully'
    puts "Submission EID: #{submission.eid}"
    puts "Form EID: #{submission.forge_eid}"
    puts "Submitted at: #{submission.submitted_at}"
  rescue Anvil::ValidationError => e
    puts "Validation Error: #{e.message}"
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 4: Submit with file uploads
puts '4. Submit form with file attachments'
puts '-' * 60

puts <<~INFO
  # To submit a form with file uploads:

  submission = form.submit(
    data: {
      full_name: "John Doe",
      email: "john@example.com",
      department: "Sales",
      message: "Please find my resume attached."
    },
    files: {
      resume: File.open("path/to/resume.pdf"),
      cover_letter: File.open("path/to/cover_letter.pdf")
    }
  )

  puts "Submitted with attachments"
  puts "Submission EID: \#{submission.eid}"
INFO

puts
puts '=' * 60
puts

# Example 5: Get all submissions
puts '5. Get all form submissions'
puts '-' * 60

if defined?(form) && form
  begin
    submissions = form.submissions(
      from: 1.week.ago,
      to: Date.today,
      limit: 10
    )

    puts "Total submissions: #{submissions.length}"

    submissions.each_with_index do |sub, idx|
      puts "\nSubmission #{idx + 1}:"
      puts "  EID: #{sub.eid}"
      puts "  Submitted: #{sub.submitted_at}"
      puts "  Name: #{sub.data[:full_name] || sub.data['full_name']}"
      puts "  Email: #{sub.data[:email] || sub.data['email']}"
      puts "  Department: #{sub.data[:department] || sub.data['department']}"
    end
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 6: Export submissions
puts '6. Export form submissions'
puts '-' * 60

if defined?(form) && form
  puts <<~INFO
    # Export submissions to CSV:

    csv_data = form.export_submissions(format: :csv)
    File.write("submissions.csv", csv_data)

    # Export submissions to JSON:

    json_data = form.export_submissions(format: :json)
    File.write("submissions.json", json_data)
  INFO
end

puts
puts '=' * 60
puts

# Example 7: Field types and validation
puts '7. Advanced field types and validation'
puts '-' * 60

puts <<~FIELD_TYPES
  # Webforms support various field types:

  form = Anvil::Webform.create(
    name: "Advanced Form",
    fields: [
      # Text inputs
      { type: "text", name: "name", label: "Name", required: true },
      { type: "email", name: "email", label: "Email", required: true },
      { type: "phone", name: "phone", label: "Phone" },
      { type: "number", name: "age", label: "Age", validation: { min: 18, max: 100 } },
  #{'    '}
      # Text areas
      { type: "textarea", name: "bio", label: "Biography" },
  #{'    '}
      # Select inputs
      { type: "select", name: "country", label: "Country",#{' '}
        options: ["USA", "Canada", "UK", "Australia"] },
      { type: "multiselect", name: "interests", label: "Interests",
        options: ["Tech", "Sports", "Music", "Art"] },
  #{'    '}
      # Checkboxes and radios
      { type: "checkbox", name: "subscribe", label: "Subscribe to newsletter" },
      { type: "radio", name: "contact_method", label: "Preferred contact",
        options: ["Email", "Phone", "SMS"] },
  #{'    '}
      # Date/time inputs
      { type: "date", name: "birth_date", label: "Birth Date" },
      { type: "time", name: "appointment", label: "Appointment Time" },
      { type: "datetime", name: "event_start", label: "Event Start" },
  #{'    '}
      # File uploads
      { type: "file", name: "document", label: "Upload Document",
        validation: { max_size: "10MB", allowed_types: ["pdf", "doc", "docx"] } }
    ]
  )
FIELD_TYPES

puts
puts '=' * 60
puts

# Example 8: Form styling
puts '8. Custom form styling'
puts '-' * 60

puts <<~STYLING
  # Customize form appearance:

  form = Anvil::Webform.create(
    name: "Branded Contact Form",
    fields: [...],
    styling: {
      theme: "modern",              # or "classic", "minimal"
      primary_color: "#007bff",     # Brand color
      background_color: "#f8f9fa",  # Background
      font_family: "Inter, sans-serif",
      border_radius: "8px",
      padding: "24px"
    },
    validation_rules: {
      email: { format: "email", message: "Please enter a valid email" },
      phone: { format: "phone", message: "Please enter a valid phone number" }
    }
  )
STYLING

puts
puts '=' * 60
puts 'Complete! Webforms provide flexible data collection'
puts 'with validation, styling, and export capabilities.'
puts '=' * 60
