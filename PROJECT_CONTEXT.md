# Anvil Ruby Gem - Project Context

## 🎯 Project Overview
Building a Ruby gem for the Anvil API (document automation and e-signatures) following Ruby best practices inspired by DHH and Matz.

**Repository:** https://github.com/nickMarz/Ruby-Anvil
**Current Version:** 0.1.0
**API Coverage:** ~30% implemented
**Ruby Version:** 3.4.8 (via rbenv)
**Development Approach:** Zero runtime dependencies using Net::HTTP

## 📁 Key Files & Locations

### Core Files
- `/Users/Nick.Marazzo/Documents/GitHub/anvil-ruby/` - Project root
- `.env` - Contains `ANVIL_API_KEY` and `ANVIL_TEMPLATE_ID`
- `.ruby-version` - Ruby 3.4.8
- `API_COVERAGE.md` - Comprehensive feature tracking (70% missing features documented)
- `PROJECT_CONTEXT.md` - This file (project reference)

### Implementation Files
- `lib/anvil.rb` - Main entry point with configuration
- `lib/anvil/resources/pdf.rb` - PDF operations (fill, generate)
- `lib/anvil/resources/signature.rb` - E-signature implementation with GraphQL
- `lib/anvil/resources/webhook.rb` - Webhook parsing and verification
- `lib/anvil/env_loader.rb` - Custom .env loader (avoiding dependencies)
- `lib/anvil/client.rb` - HTTP client with rate limiting

### Test Scripts
- `create_signature_direct.rb` - Direct GraphQL test (successfully created packet)
- `test_signature_with_template.rb` - Template-based signature test
- `test_etch_signature.rb` - E-signature connection testing

## 🚀 Current Implementation Status

### ✅ Implemented (30% of API)
1. **PDF Operations**
   - `PDF.fill` - Fill templates with JSON data
   - `PDF.generate` - Generate from HTML/CSS or Markdown
   - Save as file or base64

2. **E-Signatures (Basic)**
   - `Signature.create` - Create packets
   - `Signature.find` - Find by ID
   - `Signature.list` - List packets
   - Signing URL generation
   - Draft mode support

3. **Webhooks**
   - `Webhook.new` - Parse payloads
   - `Webhook.valid?` - Verify authenticity
   - Constant-time token validation

4. **Infrastructure**
   - Flexible API key configuration (3 methods)
   - Rate limiting with exponential backoff
   - Environment management (dev/production)
   - Error handling with specific exception types

### ❌ Missing (70% of API) - Tracked in GitHub

## 📋 GitHub Organization

### Milestones (3 phases)
1. **Phase 1: Core Features (v0.2.0)** - Essential functionality
2. **Phase 2: Advanced Features (v0.3.0)** - Advanced capabilities
3. **Phase 3: AI & Enterprise (v0.4.0)** - AI and enterprise features

### Issues Created (20 total)
- **8 parent issues** (#1-8) - High-level features
- **12 sub-issues** (#9-20) - Detailed implementation tasks

### Project Board
- **URL:** https://github.com/users/nickMarz/projects/1
- **Name:** Anvil Ruby Gem Roadmap
- Linked to Ruby-Anvil repository
- Contains all 20 issues for tracking

### Issue Breakdown

#### Phase 1 Issues
- #1: Generic GraphQL support
- #2: Complete e-signature features
  - #9: Update packet mutation
  - #10: Send packet from draft
  - #11: Delete packet
  - #12: Signer management
  - #13: Void and expire operations
- #3: Basic workflow support
  - #17: Workflow creation and retrieval
  - #18: Workflow data submission
- #4: Basic webform support
  - #19: Form creation and configuration
  - #20: Form submission handling

#### Phase 2 Issues
- #5: Cast (PDF Template) management
- #6: Webhook management API
  - #14: Webhook CRUD operations
  - #15: Webhook actions management
  - #16: Webhook logs and retry

#### Phase 3 Issues
- #7: Document AI/OCR capabilities
- #8: Organization management features

## 🔧 Technical Details

### API Endpoints
- REST API: `https://app.useanvil.com/api/v1/`
- GraphQL: `https://graphql.useanvil.com/` (NOTE: Full URL required, not just `/graphql`)

### Authentication
- Basic Auth with API key as username, empty password
- Per-request API key override supported for multi-tenancy

### Key Implementation Patterns
```ruby
# Resource-based architecture (ActiveResource style)
class Signature < Resources::Base
  def self.create(name:, signers:, files:, **options)
    # GraphQL mutation implementation
  end
end

# Flexible API key configuration
Anvil.api_key = "key"                    # Direct
ENV['ANVIL_API_KEY'] = "key"            # Environment
config.api_key = "key"                   # Rails initializer

# Zero dependencies approach
# Using Net::HTTP instead of external HTTP gems
# Custom .env loader instead of dotenv gem
```

### GraphQL Mutations Structure
```ruby
# Direct mutation parameters (not nested variables)
mutation = {
  query: <<~GRAPHQL
    mutation {
      createEtchPacket(
        name: "Test",
        isDraft: true,
        signers: [...]
      ) { ... }
    }
  GRAPHQL
}
```

## 🐛 Known Issues & Fixes Applied

1. **Ruby 3.4+ base64 extraction** - Added as explicit dependency
2. **EnvLoader regex bug** - Fixed with `line.chomp`
3. **GraphQL endpoint** - Must use full URL: `https://graphql.useanvil.com/`
4. **HTTP path issue** - Include trailing slash in URI
5. **Bundler compatibility** - Changed from `~> 2.0` to `>= 1.17`

## 📝 Environment Variables
- `ANVIL_API_KEY` - Your Anvil API key
- `ANVIL_TEMPLATE_ID` - Template EID for testing (JlLOtzZKVNA1Mljsu999od)

## 🎯 Next Steps
1. Start with Issue #1 (Generic GraphQL support) as foundation
2. Work through Phase 1 issues to reach v0.2.0
3. Each sub-issue can be a separate PR
4. Maintain zero dependencies principle
5. Keep idiomatic Ruby style (predicates, bang methods)

## 💡 Important Notes
- Gem follows Rails conventions but doesn't require Rails
- Emphasizes developer happiness (Matz's philosophy)
- Progressive disclosure: simple things simple, complex possible
- All new features should be additive (no breaking changes)
- Maintain comprehensive tests with RSpec
- Document with YARD comments

## 📚 References
- [Anvil API Docs](https://www.useanvil.com/docs/)
- [GraphQL Reference](https://www.useanvil.com/docs/api/graphql/reference/)
- [GraphQL Schema](https://app.useanvil.com/graphql/sdl) (requires auth)
- [Ruby Gems Guide](https://guides.rubygems.org/make-your-own-gem/)

## 🔄 Session Start Checklist
When starting a new session:
1. Check this file for context
2. Review `API_COVERAGE.md` for missing features
3. Check GitHub project board for current status
4. Verify environment with `ruby -v` (should be 3.4.8)
5. Ensure .env has API keys loaded
6. Run `bundle install` if needed

---
*Last Updated: January 2024*
*Created for quick context when starting new Claude sessions*