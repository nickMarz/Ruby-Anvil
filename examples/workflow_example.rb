#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating Workflow (Weld) functionality in Anvil Ruby gem

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
puts 'Anvil Workflow Examples'
puts '=' * 60
puts

# Example 1: Create a workflow
puts '1. Create a workflow'
puts '-' * 60

begin
  workflow = Anvil::Workflow.create(
    name: 'Employee Onboarding',
    forges: [ENV.fetch('ANVIL_FORM_EID_1', nil), ENV.fetch('ANVIL_FORM_EID_2', nil)].compact,
    casts: [ENV.fetch('ANVIL_TEMPLATE_EID', nil)].compact,
    steps: [
      { type: 'form', id: ENV['ANVIL_FORM_EID_1'] || 'form_1' },
      { type: 'signature', id: ENV['ANVIL_TEMPLATE_EID'] || 'template_1' }
    ].compact
  )

  puts "Created workflow: #{workflow.name}"
  puts "Workflow EID: #{workflow.eid}"
  puts "Status: #{workflow.status}"
  puts "Steps: #{workflow.steps.length}"
rescue Anvil::GraphQLError => e
  puts "GraphQL Error: #{e.message}"
rescue Anvil::Error => e
  puts "Error: #{e.message}"
  puts 'Make sure to set ANVIL_FORM_EID_1 and ANVIL_TEMPLATE_EID in .env'
end

puts
puts '=' * 60
puts

# Example 2: Get workflow details
puts '2. Get workflow details'
puts '-' * 60

if defined?(workflow) && workflow
  begin
    fetched_workflow = Anvil::Workflow.find(workflow.eid)
    puts "Workflow: #{fetched_workflow.name}"
    puts "Status: #{fetched_workflow.status}"
    puts "Published: #{fetched_workflow.published?}"
    puts "Draft: #{fetched_workflow.draft?}"
  rescue Anvil::NotFoundError => e
    puts "Workflow not found: #{e.message}"
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 3: Start a workflow
puts '3. Start a workflow submission'
puts '-' * 60

if defined?(workflow) && workflow
  begin
    submission = workflow.start(
      data: {
        employee_name: 'John Doe',
        employee_email: 'john.doe@example.com',
        start_date: Date.today.to_s,
        department: 'Engineering',
        position: 'Senior Developer'
      }
    )

    puts 'Started workflow submission'
    puts "Submission EID: #{submission.eid}"
    puts "Workflow EID: #{submission.weld_eid}"
    puts "Status: #{submission.status}"
    puts "Current step: #{submission.current_step}"
    puts "In progress: #{submission.in_progress?}"
    puts "Complete: #{submission.complete?}"
  rescue Anvil::GraphQLError => e
    puts "GraphQL Error: #{e.message}"
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 4: Continue a workflow submission
puts '4. Continue workflow from a step'
puts '-' * 60

if defined?(submission) && submission
  puts <<~INFO
    # To continue a submission from a specific step:

    submission.continue(
      step_id: "approval_step",
      data: {
        manager_name: "Jane Smith",
        manager_approval: true,
        approval_date: Date.today.to_s
      }
    )

    puts "Continued to next step"
    puts "Current step: \#{submission.current_step}"
    puts "Completed steps: \#{submission.completed_steps.length}"
  INFO
end

puts
puts '=' * 60
puts

# Example 5: Get workflow submissions
puts '5. Get all workflow submissions'
puts '-' * 60

if defined?(workflow) && workflow
  begin
    submissions = workflow.submissions(limit: 10)
    puts "Total submissions: #{submissions.length}"

    submissions.each_with_index do |sub, idx|
      puts "\nSubmission #{idx + 1}:"
      puts "  EID: #{sub.eid}"
      puts "  Status: #{sub.status}"
      puts "  Created: #{sub.created_at}"
      puts "  Completed steps: #{sub.completed_steps.length}"
    end
  rescue Anvil::Error => e
    puts "Error: #{e.message}"
  end
end

puts
puts '=' * 60
puts

# Example 6: Workflow patterns
puts '6. Common workflow patterns'
puts '-' * 60

puts <<~PATTERNS
  # Multi-step onboarding workflow
  workflow = Anvil::Workflow.create(
    name: "Complete Onboarding",
    forges: ["personal_info_form", "tax_form", "banking_form"],
    casts: ["employment_contract", "nda_template"],
    steps: [
      { type: "form", id: "personal_info_form" },
      { type: "form", id: "tax_form" },
      { type: "signature", id: "employment_contract" },
      { type: "signature", id: "nda_template" },
      { type: "form", id: "banking_form" }
    ]
  )

  # Start and track progress
  submission = workflow.start(data: employee_data)

  while submission.in_progress?
    # Wait for user to complete current step
    sleep(60)
    submission.reload!
  #{'  '}
    puts "Progress: \#{submission.completed_steps.length}/\#{workflow.steps.length}"
  end

  if submission.complete?
    puts "Onboarding complete!"
  end
PATTERNS

puts
puts '=' * 60
puts 'Complete! Workflows allow you to combine forms, PDFs,'
puts 'and signatures into multi-step document processes.'
puts '=' * 60
