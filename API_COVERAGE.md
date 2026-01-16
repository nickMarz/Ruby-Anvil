# Anvil API Coverage Documentation

## Overview
This document tracks the implementation status of Anvil API features in the anvil-ruby gem.

**Current Coverage: ~30%** of Anvil's API surface

## Implementation Status

### ✅ Implemented Features

#### PDF Operations
- [x] `PDF.fill` - Fill PDF templates with JSON data
- [x] `PDF.generate` - Generate PDFs from HTML/CSS or Markdown
- [x] `PDF.save_as` - Save PDF to file
- [x] `PDF.to_base64` - Convert to base64 encoding

#### E-Signatures (Basic)
- [x] `Signature.create` - Create signature packets
- [x] `Signature.find` - Find packet by ID
- [x] `Signature.list` - List signature packets
- [x] `signing_url` - Generate signing URLs for signers
- [x] Draft mode support

#### Webhooks
- [x] `Webhook.new` - Parse webhook payloads
- [x] `Webhook.valid?` - Verify webhook authenticity
- [x] Token validation with constant-time comparison
- [x] Basic webhook action detection

#### Core Infrastructure
- [x] API key configuration (multiple methods)
- [x] Environment management (development/production)
- [x] Rate limiting with exponential backoff
- [x] Error handling with specific exception types
- [x] .env file support

### ❌ Missing Features

#### 1. Workflows API (Priority: HIGH)
**Purpose:** Automate document workflows combining forms, PDFs, and signatures

Missing endpoints:
- [ ] `createWeld` - Create workflow
- [ ] `updateWeld` - Update workflow configuration
- [ ] `duplicateWeld` - Clone workflow
- [ ] `publishWeld` - Publish workflow
- [ ] `mergeWelds` - Merge multiple workflows
- [ ] `weld` query - Get workflow details
- [ ] `weldData` query - Get workflow submission data

Proposed Ruby interface:
```ruby
Anvil::Workflow.create(name:, forges:, casts:)
Anvil::Workflow.find(id)
Anvil::Workflow.start(workflow_id, data: {})
Anvil::Workflow.submissions(workflow_id)
```

#### 2. Webforms/Forge API (Priority: HIGH)
**Purpose:** Create and manage data collection forms

Missing endpoints:
- [ ] `createForge` - Create webform
- [ ] `updateForge` - Update webform
- [ ] `forge` query - Get form configuration
- [ ] `createSubmission` - Submit form data
- [ ] `updateSubmission` - Update submission
- [ ] `submission` query - Get submission data

Proposed Ruby interface:
```ruby
Anvil::Webform.create(name:, fields:)
Anvil::Webform.find(id)
Anvil::Webform.submit(form_id, data:)
Anvil::Webform.submissions(form_id)
```

#### 3. Document AI / OCR (Priority: MEDIUM)
**Purpose:** Extract data from documents using AI/OCR

Missing capabilities:
- [ ] Text extraction from PDFs
- [ ] Field detection and labeling
- [ ] Document classification
- [ ] Structured data extraction

Proposed Ruby interface:
```ruby
Anvil::DocumentAI.extract_text(file:)
Anvil::DocumentAI.identify_fields(file:)
Anvil::DocumentAI.extract_data(file:, schema:)
```

#### 4. Cast (PDF Template) Management (Priority: MEDIUM)
**Purpose:** Programmatically manage PDF templates

Missing endpoints:
- [ ] `createCast` - Create template
- [ ] `updateCast` - Update template
- [ ] `duplicateCast` - Clone template
- [ ] `publishCast` - Publish template
- [ ] `cast` query - Get template details

Proposed Ruby interface:
```ruby
Anvil::Cast.create(file:, fields:)
Anvil::Cast.update(id, fields:)
Anvil::Cast.duplicate(id)
Anvil::Cast.list
```

#### 5. Advanced E-Signature Features (Priority: HIGH)
**Purpose:** Complete signature packet management

Missing endpoints:
- [ ] `updateEtchPacket` - Update packet
- [ ] `sendEtchPacket` - Send packet (from draft)
- [ ] `removeEtchPacket` - Delete packet
- [ ] `skipSigner` - Skip a signer
- [ ] `notifySigner` - Send reminder
- [ ] `updateEtchTemplate` - Update template
- [ ] `voidDocumentGroup` - Void signed documents
- [ ] `expireSignerTokens` - Expire signing sessions

Proposed Ruby interface:
```ruby
packet.update(name:, signers:)
packet.send!
packet.delete!
packet.skip_signer(signer_id)
packet.notify_signer(signer_id)
packet.void!
```

#### 6. Organization Management (Priority: LOW)
**Purpose:** Manage organization settings and users

Missing endpoints:
- [ ] `organization` query - Get org details
- [ ] `updateOrganization` - Update settings
- [ ] `updateOrganizationUser` - Manage users
- [ ] `currentUser` query - Get current user

Proposed Ruby interface:
```ruby
Anvil::Organization.get
Anvil::Organization.update(settings:)
Anvil::Organization.users
Anvil::Organization.add_user(email:, role:)
```

#### 7. Embedded Builders (Priority: LOW)
**Purpose:** Embed Anvil UI builders in your application

Missing endpoints:
- [ ] `generateEmbedURL` - Create embed session
- [ ] Session management

Proposed Ruby interface:
```ruby
Anvil::EmbeddedBuilder.generate_url(type:, options:)
Anvil::EmbeddedBuilder.create_session
```

#### 8. Webhook Management (Priority: MEDIUM)
**Purpose:** Programmatically manage webhooks

Missing endpoints:
- [ ] `createWebhook` - Create webhook
- [ ] `updateWebhook` - Update webhook
- [ ] `removeWebhook` - Delete webhook
- [ ] `createWebhookAction` - Create webhook action
- [ ] `removeWebhookAction` - Remove action
- [ ] `webhookLog` query - Get webhook logs
- [ ] `retryWebhookLog` - Retry failed webhook

Proposed Ruby interface:
```ruby
Anvil::Webhook.create(url:, events:)
Anvil::Webhook.update(id, url:)
Anvil::Webhook.delete(id)
Anvil::WebhookLog.list
Anvil::WebhookLog.retry(id)
```

#### 9. Generic GraphQL Support (Priority: HIGH)
**Purpose:** Allow custom GraphQL queries/mutations

Proposed Ruby interface:
```ruby
Anvil::Client.query(graphql_string, variables: {})
Anvil::Client.mutation(graphql_string, variables: {})
```

## GraphQL Operations Summary

### Available Queries (9 total)
- `cast` - PDF template details
- `currentUser` - User info
- `etchPacket` - Signature packet
- `forge` - Webform config
- `organization` - Org details
- `signer` - Signer info
- `submission` - Form submission
- `webhookLog` - Webhook history
- `weld` - Workflow config
- `weldData` - Workflow data

### Available Mutations (35 total)

**Document Operations (11):**
- createCast, updateCast, duplicateCast, publishCast
- createWeld, updateWeld, duplicateWeld, publishWeld, mergeWelds
- createForge, updateForge

**E-Signature (6):**
- createEtchPacket, updateEtchPacket, sendEtchPacket
- removeEtchPacket, generateEtchSignURL, updateEtchTemplate

**Workflow Data (6):**
- createWeldData, updateWeldData, removeWeldData
- createSubmission, updateSubmission, destroySubmission

**Configuration (7):**
- createWebhook, updateWebhook, removeWebhook
- createWebhookAction, removeWebhookAction
- updateOrganization, updateOrganizationUser

**Utilities (5):**
- generateEmbedURL, expireSessionToken, expireSignerTokens
- notifySigner, skipSigner, retryWebhookLog
- disconnectDocusign, voidDocumentGroup

## Implementation Phases

### Phase 1: Core Features (v0.2.0)
1. Generic GraphQL support
2. Complete e-signature features
3. Basic workflow support
4. Basic webform support

### Phase 2: Advanced Features (v0.3.0)
1. Full workflow implementation
2. Full webform implementation
3. Cast management
4. Webhook management

### Phase 3: AI & Enterprise (v0.4.0)
1. Document AI/OCR
2. Organization management
3. Embedded builders
4. Advanced utilities

## Testing Requirements

Each feature implementation should include:
1. Unit tests (RSpec)
2. Integration tests (with VCR cassettes)
3. Documentation (YARD comments)
4. Usage examples
5. Error handling tests

## Dependencies

Current gem has zero runtime dependencies (except base64 for Ruby 3.4+).
We should maintain this approach where possible.

Optional dependencies to consider:
- `multipart-post` - For file uploads (already optional)
- `marcel` - For MIME type detection (if needed)

## Breaking Changes

None expected. All new features will be additive.

## Notes for Implementation

1. Maintain consistent API design with existing patterns
2. Use resource-based architecture (ActiveResource-like)
3. Keep methods idiomatic Ruby (predicates, bang methods)
4. Provide both simple and advanced interfaces
5. Handle errors consistently with existing error classes
6. Support per-request API key overrides for multi-tenancy

## References

- [Anvil API Documentation](https://www.useanvil.com/docs/)
- [GraphQL Reference](https://www.useanvil.com/docs/api/graphql/reference/)
- [GraphQL Schema](https://app.useanvil.com/graphql/sdl) (requires auth)

---
*Last Updated: January 2024*
*Current Gem Version: 0.1.0*