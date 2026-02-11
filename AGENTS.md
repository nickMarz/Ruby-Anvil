# AGENTS.md

## Project Overview

**anvil-ruby** is a Ruby gem providing a client for the [Anvil API](https://www.useanvil.com/docs/) — a document automation platform for PDF filling, PDF generation, e-signatures, and webhooks.

- **Version:** 0.1.0
- **Ruby:** >= 2.5.0 (developed on 3.4.8 via rbenv)
- **License:** MIT
- **Repo:** https://github.com/nickMarz/Ruby-Anvil
- **API coverage:** ~30% implemented

## Commands

```bash
bundle install                # Install dependencies
bundle exec rspec             # Run tests
bundle exec rspec --format documentation  # Verbose test output
bundle exec rubocop           # Lint / style check
bundle exec rake install      # Install gem locally
gem build anvil-ruby.gemspec  # Build the gem
```

Always run `bundle exec rubocop` and `bundle exec rspec` before committing.

## Architecture

```
lib/
  anvil.rb                    # Entry point, module-level configuration
  anvil/
    version.rb                # VERSION constant
    configuration.rb          # Configuration class (api_key, environment, timeouts)
    client.rb                 # HTTP client (Net::HTTP), auth, request building
    errors.rb                 # Error hierarchy (APIError, ValidationError, etc.)
    rate_limiter.rb           # Retry with exponential backoff
    response.rb               # Response wrapper (JSON parsing, rate-limit headers)
    env_loader.rb             # Custom .env file parser (no dotenv dependency)
    resources/
      base.rb                 # Base resource class (ActiveRecord-like attributes)
      pdf.rb                  # PDF.fill, PDF.generate, PDF.generate_from_html/markdown
      signature.rb            # Signature packets (create, find, list) via GraphQL
      webhook.rb              # Webhook parsing, token verification, decryption
```

### Key patterns

- **Resource-based architecture** — resources inherit from `Resources::Base` which provides attribute accessors via `method_missing`, serialization, and a class-level `client`.
- **Zero runtime dependencies** — only Ruby stdlib (`net/http`, `json`, `base64`, `uri`, `openssl`). The `base64` gem is added for Ruby 3.4+ compatibility.
- **GraphQL for signatures** — `Signature` resource posts to `https://graphql.useanvil.com/` (full URL, not relative path).
- **REST for PDFs** — `PDF` resource uses REST endpoints at `https://app.useanvil.com/api/v1/`.
- **Multi-tenancy** — per-request `api_key:` override on resource methods.
- **Configuration** — three methods: `Anvil.configure` block, `Anvil.api_key=`, or `ANVIL_API_KEY` env var.

## Testing

- **Framework:** RSpec (with `--format documentation` and `--color` via `.rspec`)
- **HTTP mocking:** WebMock + VCR (optional; loaded if available)
- **Spec structure** mirrors `lib/` — e.g., `spec/anvil/resources/pdf_spec.rb`
- Config is reset before each test; `ANVIL_API_KEY` is stubbed to `'test_api_key'`
- Use `:configured` metadata tag for tests that need `Anvil.configure` called

## Code Style

- **RuboCop** with `rubocop-rspec` (see `.rubocop.yml`)
- Single quotes for strings
- `frozen_string_literal: true` in every file
- Max line length: 120
- Max method length: 25
- No `Style/Documentation` enforcement
- Idiomatic Ruby: predicate methods (`complete?`, `draft?`), bang methods (`reload!`, `save_as!`)

## Error Hierarchy

```
Anvil::Error
├── ConfigurationError
├── APIError
│   ├── ValidationError
│   ├── AuthenticationError
│   ├── RateLimitError
│   ├── NotFoundError
│   └── ServerError
├── NetworkError
│   ├── TimeoutError
│   └── ConnectionError
├── FileError
│   ├── FileNotFoundError
│   └── FileTooLargeError
└── WebhookError
    └── WebhookVerificationError
```

## Environment Variables

| Variable | Purpose |
|---|---|
| `ANVIL_API_KEY` | API key for Anvil |
| `ANVIL_WEBHOOK_TOKEN` | Token for webhook verification |
| `ANVIL_TEMPLATE_ID` | Template EID for testing |
| `ANVIL_ENV` | Environment override (`development` / `production`) |
| `ANVIL_RSA_PRIVATE_KEY_PATH` | RSA key for webhook decryption |

## CI/CD

- **GitHub Actions** — CI pipeline in `.github/workflows/ci.yml` (tests, lint, security)
- **Gem publishing** — `.github/workflows/gem-push.yml` (triggered by version tags like `v0.2.0`)
- **Dependabot** — weekly dependency updates

## Releasing

1. Update `lib/anvil/version.rb`
2. Update `CHANGELOG.md`
3. Commit and tag: `git tag v0.x.x`
4. Push: `git push origin main --tags`

## Conventions

- Zero runtime dependencies — use only Ruby stdlib
- Rails-friendly but framework-agnostic
- Semantic versioning; all new features are additive (no breaking changes)
- Document new features in CHANGELOG.md and API_COVERAGE.md
- Write RSpec tests for all new functionality
