# Anvil Ruby

A Ruby gem for the [Anvil API](https://www.useanvil.com/docs/) - the fastest way to build document workflows.

[![CI](https://github.com/nickMarz/Ruby-Anvil/workflows/CI/badge.svg)](https://github.com/nickMarz/Ruby-Anvil/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/anvil-ruby.svg)](https://badge.fury.io/rb/anvil-ruby)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-red.svg)](https://github.com/nickMarz/Ruby-Anvil/blob/main/.ruby-version)

Anvil is a suite of tools for managing document workflows:

- 📝 **PDF Filling** - Fill PDF templates with JSON data
- 📄 **PDF Generation** - Generate PDFs from HTML/CSS or Markdown
- ✍️ **E-signatures** - Collect legally binding e-signatures
- 🔄 **Webhooks** - Real-time notifications for document events

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'anvil-ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install anvil-ruby
```

## Feature Status

Current coverage: **~60% of Anvil's API**. See [API_COVERAGE.md](API_COVERAGE.md) for detailed implementation status.

### ✅ Implemented
- **PDF Operations** - Fill templates, generate from HTML/Markdown
- **E-Signatures (Complete)** - Create, update, send, delete packets; manage signers; void documents
- **Workflows** - Create workflows, start submissions, track progress
- **Webforms** - Create forms, submit data, export submissions
- **Webhooks** - Parse payloads, verify authenticity
- **GraphQL Support** - Generic query/mutation interface for any API endpoint
- **Core Infrastructure** - Rate limiting, error handling, flexible configuration

### 🚧 Roadmap

#### Phase 2: Advanced Features (v0.3.0)
- [ ] Cast (PDF template) management (create, update, publish)
- [ ] Webhook management API (CRUD operations, logs, retry)

#### Phase 3: AI & Enterprise (v0.4.0)
- [ ] Document AI/OCR capabilities
- [ ] Organization management
- [ ] Embedded builders
- [ ] Advanced utilities

See our [GitHub Projects](https://github.com/nickMarz/Ruby-Anvil/projects) for detailed progress tracking.

## Quick Start

### Configuration

Configure your API key (get one at [Anvil Settings](https://app.useanvil.com/organizations/settings/api)):

#### Rails (config/initializers/anvil.rb)

```ruby
Anvil.configure do |config|
  config.api_key = Rails.application.credentials.anvil[:api_key]
  config.environment = Rails.env.production? ? :production : :development
end
```

#### Environment Variable

```bash
export ANVIL_API_KEY="your_api_key_here"
```

#### Direct Assignment

```ruby
require 'anvil'
Anvil.api_key = "your_api_key_here"
```

## Usage

### PDF Filling

Fill PDF templates with your data:

```ruby
# Fill a PDF template
pdf = Anvil::PDF.fill(
  template_id: "your_template_id",
  data: {
    name: "John Doe",
    email: "john@example.com",
    date: Date.today.strftime("%B %d, %Y")
  }
)

# Save the filled PDF
pdf.save_as("contract.pdf")

# Get as base64 (for database storage)
base64_pdf = pdf.to_base64
```

### PDF Generation

#### Generate from HTML/CSS

```ruby
pdf = Anvil::PDF.generate_from_html(
  html: "<h1>Invoice #123</h1><p>Amount: $100</p>",
  css: "h1 { color: blue; }",
  title: "Invoice"
)

pdf.save_as("invoice.pdf")
```

#### Generate from Markdown

```ruby
pdf = Anvil::PDF.generate_from_markdown(
  <<~MD
    # Report

    ## Summary
    This is a **markdown** document with:
    - Bullet points
    - *Italic text*
    - [Links](https://anvil.com)
  MD
)

pdf.save_as("report.pdf")
```

### E-Signatures

Create and manage e-signature packets:

```ruby
# Create a signature packet
packet = Anvil::Signature.create(
  name: "Employment Agreement",
  signers: [
    {
      name: "John Doe",
      email: "john@example.com",
      role: "employee"
    },
    {
      name: "Jane Smith",
      email: "jane@company.com",
      role: "manager"
    }
  ],
  files: [
    { type: :pdf, id: "template_id_here" }
  ]
)

# Get signing URL for a signer
signer = packet.signers.first
signing_url = signer.signing_url

# Check status
packet.reload!
if packet.complete?
  puts "All signatures collected!"
end

# Update a packet
packet.update(
  name: "Updated Agreement",
  signers: [...]
)

# Send a draft packet
packet.send!

# Skip a signer
packet.skip_signer("signer_eid")

# Send reminder
signer = packet.signers.first
signer.send_reminder!

# Delete a draft packet
packet.delete!

# Void completed documents
packet.void!(reason: "Contract cancelled")
```

### Workflows

Create and manage multi-step document workflows:

```ruby
# Create a workflow
workflow = Anvil::Workflow.create(
  name: "Employee Onboarding",
  forges: ["form_id_1", "form_id_2"],  # Form IDs
  casts: ["template_id_1"]             # PDF template IDs
)

# Get workflow
workflow = Anvil::Workflow.find("workflow_eid")

# Start workflow with initial data
submission = workflow.start(
  data: {
    employee_name: "John Doe",
    employee_email: "john@example.com",
    start_date: "2024-02-01"
  }
)

# Check submission status
submission.status          # "in_progress" or "complete"
submission.current_step
submission.completed_steps

# Continue workflow from a step
submission.continue(
  step_id: "approval_step",
  data: { manager_approval: true }
)

# Get all workflow submissions
submissions = workflow.submissions(
  status: "complete",
  limit: 10
)
```

### Webforms

Create and manage data collection forms:

```ruby
# Create a webform
form = Anvil::Webform.create(
  name: "Contact Form",
  fields: [
    {
      type: "text",
      name: "full_name",
      label: "Full Name",
      required: true
    },
    {
      type: "email",
      name: "email",
      label: "Email Address",
      validation: { format: "email" }
    },
    {
      type: "select",
      name: "department",
      label: "Department",
      options: ["Sales", "Support", "Engineering"]
    }
  ],
  styling: {
    theme: "modern",
    primary_color: "#007bff"
  }
)

# Get form
form = Anvil::Webform.find("form_eid")

# Submit form data
submission = form.submit(
  data: {
    full_name: "Jane Smith",
    email: "jane@example.com",
    department: "Engineering"
  },
  files: {
    resume: File.open("resume.pdf")
  }
)

# Get all submissions
submissions = form.submissions(
  from: 1.week.ago,
  to: Date.today,
  limit: 100
)

# Export submissions
csv_data = form.export_submissions(format: :csv)
```

### Webhooks

Handle webhook events from Anvil:

#### Rails Controller

```ruby
class AnvilWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    webhook = Anvil::Webhook.new(
      payload: request.body.read,
      token: params[:token]
    )

    if webhook.valid?
      case webhook.action
      when 'signerComplete'
        handle_signer_complete(webhook.data)
      when 'etchPacketComplete'
        handle_packet_complete(webhook.data)
      end

      head :no_content
    else
      head :unauthorized
    end
  end

  private

  def handle_signer_complete(data)
    # Process signer completion
    SignerCompleteJob.perform_later(data)
  end

  def handle_packet_complete(data)
    # All signatures collected
    PacketCompleteJob.perform_later(data)
  end
end
```

#### Sinatra/Rack

```ruby
post '/webhooks/anvil' do
  webhook = Anvil::Webhook.new(
    payload: request.body.read,
    token: params[:token]
  )

  halt 401 unless webhook.valid?

  # Process webhook
  case webhook.action
  when 'signerComplete'
    # Handle signer completion
  end

  status 204
end
```

## Advanced Usage

### Generic GraphQL Support

For features not yet wrapped by the gem, you can execute custom GraphQL queries and mutations:

```ruby
# Execute a custom query
response = Anvil.query(
  query: <<~GRAPHQL,
    query GetCurrentUser {
      currentUser {
        eid
        name
        email
      }
    }
  GRAPHQL
  variables: {}
)

user = response.data[:data][:currentUser]

# Execute a custom mutation
response = Anvil.mutation(
  mutation: <<~GRAPHQL,
    mutation CreateCast($input: JSON) {
      createCast(input: $input) {
        eid
        name
      }
    }
  GRAPHQL
  variables: {
    input: {
      name: "My Template",
      file: base64_pdf
    }
  }
)

# Use with custom client for multi-tenancy
client = Anvil::Client.new(api_key: tenant_key)
response = client.query(query: graphql_query, variables: vars)
```

See the [GraphQL Reference](https://www.useanvil.com/docs/api/graphql/reference/) for available queries and mutations.

### Multi-tenant Applications

Use different API keys per request:

```ruby
# Override API key for specific operations
pdf = Anvil::PDF.fill(
  template_id: "template_123",
  data: { name: "John" },
  api_key: current_tenant.anvil_api_key
)

# Or create a custom client
client = Anvil::Client.new(api_key: tenant.api_key)
pdf = Anvil::PDF.new(client: client).fill(...)
```

### Error Handling

The gem provides specific error types for different scenarios:

```ruby
begin
  pdf = Anvil::PDF.fill(template_id: "123", data: {})
rescue Anvil::ValidationError => e
  # Invalid data or parameters
  puts "Validation failed: #{e.message}"
  puts "Errors: #{e.errors}"
rescue Anvil::AuthenticationError => e
  # Invalid or missing API key
  puts "Auth failed: #{e.message}"
rescue Anvil::GraphQLError => e
  # GraphQL query/mutation errors
  puts "GraphQL error: #{e.message}"
rescue Anvil::RateLimitError => e
  # Rate limit exceeded
  puts "Rate limited. Retry after: #{e.retry_after} seconds"
rescue Anvil::NotFoundError => e
  # Resource not found
  puts "Not found: #{e.message}"
rescue Anvil::NetworkError => e
  # Network issues
  puts "Network error: #{e.message}"
rescue Anvil::Error => e
  # Generic Anvil error
  puts "Error: #{e.message}"
end
```

### Rate Limiting

The gem automatically handles rate limiting with exponential backoff:

```ruby
# Configure custom retry behavior
client = Anvil::Client.new
client.rate_limiter = Anvil::RateLimiter.new(
  max_retries: 5,
  base_delay: 2.0
)
```

### Development Mode

Enable development mode for watermarked PDFs and debug output:

```ruby
Anvil.configure do |config|
  config.api_key = "your_dev_key"
  config.environment = :development  # Watermarks PDFs, verbose logging
end
```

## Configuration Options

```ruby
Anvil.configure do |config|
  # Required
  config.api_key = "your_api_key"

  # Optional
  config.environment = :production  # :development or :production
  config.base_url = "https://app.useanvil.com/api/v1"  # API endpoint
  config.timeout = 120  # Read timeout in seconds
  config.open_timeout = 30  # Connection timeout
  config.webhook_token = "your_webhook_token"  # For webhook verification
end
```

## Examples

See the [examples](examples/) directory for complete working examples:

- [PDF Filling](examples/fill_pdf.rb)
- [PDF Generation](examples/generate_pdf.rb)
- [E-signatures](examples/create_signature.rb)
- [Workflows](examples/workflow_example.rb)
- [Webforms](examples/webform_example.rb)
- [Webhook Handling](examples/verify_webhook.rb)
- [Generic GraphQL Queries](examples/graphql_generic.rb)

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec  # Run tests
bundle exec rubocop  # Check code style
```

To install this gem onto your local machine:

```bash
bundle exec rake install
```

## Testing

The gem uses RSpec for testing:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/anvil/pdf_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

## CI/CD with GitHub Actions

This project uses GitHub Actions for continuous integration and automated gem publishing.

### Automated Workflows

- **CI Pipeline** - Runs tests, linting, and security checks on every push and PR
- **Gem Publishing** - Automatically publishes to RubyGems.org when you create a version tag
- **Dependency Updates** - Dependabot keeps dependencies up-to-date weekly

### Quick Start

1. Fork the repository
2. Add your `RUBYGEMS_AUTH_TOKEN` secret to GitHub (Settings → Secrets)
3. Push your changes - CI will run automatically
4. Create a version tag to publish: `git tag v0.2.0 && git push --tags`

See [.github/workflows/README.md](.github/workflows/README.md) for complete documentation on:
- Setting up secrets and authentication
- Running workflows manually
- Debugging CI failures
- Security best practices
- Customizing workflows

## Philosophy

This gem embraces Ruby's philosophy of developer happiness:

- **Zero runtime dependencies** - Uses only Ruby's standard library
- **Rails-friendly** - Works great with Rails but doesn't require it
- **Idiomatic Ruby** - Follows Ruby conventions (predicates, bang methods, blocks)
- **Progressive disclosure** - Simple things are simple, complex things are possible

## Contributing

1. Fork it (https://github.com/nickMarz/Ruby-Anvil/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please make sure to:
- Add tests for new features
- Follow Ruby style guide (run `rubocop`)
- Update documentation
- Ensure all CI checks pass (tests, linting, security)
- Check the GitHub Actions tab to monitor your PR's build status

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Support

- 📚 [Anvil Documentation](https://www.useanvil.com/docs/)
- 💬 [API Reference](https://www.useanvil.com/docs/api/)
- 🐛 [Report Issues](https://github.com/nickMarz/Ruby-Anvil/issues)
- 📧 [Contact Support](https://www.useanvil.com/contact)

## Acknowledgments

Built with ❤️ by Ruby developers, for Ruby developers. Inspired by the elegance of Rails and the philosophy of Matz.

Special thanks to DHH and Matz for making Ruby a joy to work with.
