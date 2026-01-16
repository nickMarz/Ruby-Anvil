# GitHub Actions Quick Reference

## 🚀 Common Tasks

### Publishing a New Version

```bash
# 1. Update version in lib/anvil/version.rb
# 2. Update CHANGELOG.md
# 3. Commit and tag
git add -A
git commit -m "Release v0.2.0"
git tag v0.2.0
git push origin main --tags

# The gem will automatically be published to RubyGems
```

### Running CI Locally

```bash
# Run all checks that CI runs
bundle exec rubocop           # Linting
bundle exec rspec             # Tests
bundle-audit check --update   # Security audit
gem build *.gemspec          # Build gem
```

### Debugging Failed Builds

```bash
# View GitHub Actions logs
# 1. Go to: https://github.com/nickMarz/Ruby-Anvil/actions
# 2. Click on the failed workflow run
# 3. Click on the failed job to see logs

# Run specific Ruby version locally (using rbenv)
rbenv install 3.2.0
rbenv local 3.2.0
bundle install
bundle exec rspec

# Run with verbose output
bundle exec rspec --format documentation --backtrace
```

### Manual Workflow Triggers

```bash
# Using GitHub CLI
gh workflow run ci.yml --ref main
gh workflow run gem-push.yml --ref main

# Or use the GitHub UI:
# Actions tab → Select workflow → Run workflow
```

## 📋 Required Secrets

| Secret | Where to Get | Required For |
|--------|--------------|--------------|
| `RUBYGEM_API_KEY` | [rubygems.org/profile/api_keys](https://rubygems.org/profile/api_keys) | Publishing gems |
| `ANVIL_API_KEY` | Anvil Dashboard | Running tests (optional) |

## 🔧 Workflow Files

| File | Purpose | Triggers |
|------|---------|----------|
| `.github/workflows/ci.yml` | Tests, linting, security | Push, PR |
| `.github/workflows/gem-push.yml` | Publish to RubyGems | Version tags |
| `.github/dependabot.yml` | Dependency updates | Weekly |

## 🏷️ Version Tags

```bash
# Create a version tag
git tag v0.2.0

# Push tag to trigger gem publication
git push origin v0.2.0

# List all tags
git tag -l

# Delete a tag (if needed)
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0
```

## 🔍 Status Checks

Before merging PRs, ensure these checks pass:
- ✅ Lint (RuboCop)
- ✅ Test (Ruby 2.7, 3.0, 3.1, 3.2, 3.3)
- ✅ Build
- ✅ Security

## 🆘 Troubleshooting

### RubyGems Publication Failed
```bash
# Check if secret is set
# Settings → Secrets → Actions → RUBYGEM_API_KEY

# Verify API key permissions at rubygems.org
# Should have "Push rubygems" scope

# Test locally
gem push *.gem --key your_api_key
```

### Tests Pass Locally but Fail in CI
```bash
# Check Ruby version
ruby -v

# Check for environment variables
env | grep ANVIL

# Use same bundler version
gem install bundler -v $(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -1 | tr -d ' ')
```

### Rate Limiting Issues
```yaml
# Add to workflow if experiencing issues
- name: Wait to avoid rate limits
  run: sleep 60
```

## 📊 Monitoring

- **Actions Dashboard**: [github.com/nickMarz/Ruby-Anvil/actions](https://github.com/nickMarz/Ruby-Anvil/actions)
- **Workflow Usage**: Settings → Billing & plans → Usage this month
- **Dependabot PRs**: Pull requests → Filter: `author:app/dependabot`

## 🔐 Security

```bash
# Run security audit locally
bundle-audit check --update

# Update vulnerable gems
bundle update gem_name

# Check for leaked secrets
# Never commit .env or credentials files!
git secrets --scan
```

## 📝 Useful Commands

```bash
# See all GitHub CLI workflow commands
gh workflow --help

# List all workflows
gh workflow list

# View recent runs
gh run list

# Watch a run in progress
gh run watch

# View workflow file
gh workflow view ci.yml

# Download artifacts
gh run download [run-id]
```

---
*For detailed documentation, see [.github/workflows/README.md](.github/workflows/README.md)*