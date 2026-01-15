# Anvil Ruby

A Ruby gem for the [Anvil API](https://www.useanvil.com/docs/) - the fastest way to build document workflows.

[![Gem Version](https://badge.fury.io/rb/anvil-ruby.svg)](https://badge.fury.io/rb/anvil-ruby)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

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
- [Webhook Handling](examples/verify_webhook.rb)

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
