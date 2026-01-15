# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-01-15

### Added
- Initial release of the Anvil Ruby gem
- PDF filling support via `Anvil::PDF.fill`
- PDF generation from HTML/CSS via `Anvil::PDF.generate_from_html`
- PDF generation from Markdown via `Anvil::PDF.generate_from_markdown`
- E-signature packet creation and management via `Anvil::Signature`
- Webhook verification and handling via `Anvil::Webhook`
- Flexible API key configuration (Rails initializer, environment variable, direct assignment)
- Multi-tenant support with per-request API key override
- Automatic rate limiting with exponential backoff
- Comprehensive error handling with specific exception types
- Zero runtime dependencies - uses only Ruby standard library
- Rails-friendly design while remaining framework agnostic
- Full RSpec test suite
- Extensive documentation and examples

### Security
- Secure webhook token verification with constant-time comparison
- Support for RSA-encrypted webhook payloads
- MFA required for RubyGems publishing

[Unreleased]: https://github.com/nickMarz/Ruby-Anvil/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nickMarz/Ruby-Anvil/releases/tag/v0.1.0