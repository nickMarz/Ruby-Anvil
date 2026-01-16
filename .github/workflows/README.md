# GitHub Actions Documentation

This repository uses GitHub Actions for continuous integration, testing, and automated gem publishing.

## 📋 Table of Contents

- [Workflows Overview](#workflows-overview)
- [Setup Instructions](#setup-instructions)
- [Workflow Details](#workflow-details)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## 🔄 Workflows Overview

We have three main automation systems:

| Workflow | Purpose | Triggers | Badge |
|----------|---------|----------|-------|
| **CI** | Run tests, linting, and security checks | Push to main/PR | ![CI](https://github.com/nickMarz/Ruby-Anvil/workflows/CI/badge.svg) |
| **Ruby Gem** | Publish gem to RubyGems and GitHub Packages | Version tags (v*) | ![Gem](https://github.com/nickMarz/Ruby-Anvil/workflows/Ruby%20Gem/badge.svg) |
| **Dependabot** | Automated dependency updates | Weekly schedule | N/A |

## 🚀 Setup Instructions

### Prerequisites

1. **GitHub Repository Settings**
   - Ensure Actions are enabled: Settings → Actions → General
   - Set permissions: Allow all actions and reusable workflows

2. **Required Secrets**

   Navigate to: Settings → Secrets and variables → Actions → New repository secret

   | Secret Name | Required | Description | How to Get |
   |------------|----------|-------------|------------|
   | `RUBYGEM_API_KEY` | Yes (for publishing) | RubyGems.org API key | [Create at rubygems.org](https://rubygems.org/profile/api_keys) |
   | `ANVIL_API_KEY` | Optional | Anvil API key for tests | From your Anvil dashboard |

### Setting up RubyGems Authentication

1. Go to https://rubygems.org/profile/api_keys
2. Sign in with your RubyGems account
3. Click "New API Key"
4. Name: `anvil-ruby-github-actions`
5. Scope: Select "Push rubygems"
6. Copy the generated key
7. Add to GitHub Secrets as `RUBYGEM_API_KEY`

## 📁 Workflow Details

### CI Workflow (`ci.yml`)

**Purpose:** Ensures code quality and functionality on every change.

**Jobs:**

1. **Lint**
   - Runs RuboCop for Ruby style guide enforcement
   - Uses `.rubocop.yml` configuration
   - Fails on any style violations

2. **Test**
   - Matrix testing across Ruby versions: 2.7, 3.0, 3.1, 3.2, 3.3
   - Runs RSpec test suite
   - Generates code coverage report
   - Uploads coverage to Codecov (Ruby 3.2 only)

3. **Build**
   - Builds the gem to ensure it packages correctly
   - Only runs if lint and test pass
   - Uploads gem artifact for inspection

4. **Security**
   - Runs `bundler-audit` for known vulnerabilities
   - Checks for Rails-specific issues with Brakeman (if applicable)

**Triggers:**
- Push to `main`, `master`, or `develop` branches
- Pull requests to these branches
- Manual trigger via GitHub UI

### Ruby Gem Workflow (`gem-push.yml`)

**Purpose:** Automates gem publication when releasing new versions.

**Process:**
1. Triggers on version tags (e.g., `v1.0.0`)
2. Builds the gem
3. Creates GitHub release with changelog
4. Publishes to RubyGems.org
5. Publishes to GitHub Package Registry

**Triggers:**
- Push of tags matching `v*` pattern
- Manual trigger via GitHub UI

### Dependabot Configuration (`dependabot.yml`)

**Purpose:** Keeps dependencies up-to-date automatically.

**Configuration:**
- **Bundler:** Weekly updates for Ruby gems
  - Groups development dependencies together
  - Limits to 10 open PRs
- **GitHub Actions:** Weekly updates for action versions

## 📖 Usage Guide

### Running Tests Locally

Before pushing, you can run the same checks locally:

```bash
# Run linting
bundle exec rubocop

# Run tests
bundle exec rspec

# Run security audit
bundle-audit check --update

# Build the gem
gem build anvil-ruby.gemspec
```

### Creating a New Release

1. **Update the version number:**
   ```ruby
   # lib/anvil/version.rb
   module Anvil
     VERSION = "0.2.0"  # Update this
   end
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [0.2.0] - 2024-01-15
   ### Added
   - New feature X
   ### Fixed
   - Bug Y
   ```

3. **Commit and tag:**
   ```bash
   git add -A
   git commit -m "Release version 0.2.0"
   git tag v0.2.0
   git push origin main --tags
   ```

4. **Monitor the release:**
   - Go to Actions tab in GitHub
   - Watch the "Ruby Gem" workflow
   - Check the release appears on RubyGems.org

### Manual Workflow Runs

You can manually trigger workflows:

1. Go to Actions tab
2. Select the workflow (CI or Ruby Gem)
3. Click "Run workflow"
4. Select branch and click "Run workflow"

### Handling CI Failures

**Linting Failures:**
```bash
# Auto-fix many issues
bundle exec rubocop -A

# Check specific file
bundle exec rubocop path/to/file.rb
```

**Test Failures:**
```bash
# Run specific test
bundle exec rspec spec/path/to/test_spec.rb

# Run with verbose output
bundle exec rspec --format documentation
```

**Build Failures:**
```bash
# Check gemspec is valid
gem build anvil-ruby.gemspec

# Verify all required files are included
git ls-files
```

## 🔧 Troubleshooting

### Common Issues

#### 1. RubyGems Publication Fails

**Error:** `Your rubygems.org credentials aren't set`

**Solution:**
- Verify `RUBYGEM_API_KEY` secret is set correctly
- Ensure the API key has "Push rubygems" permission
- Check the API key hasn't expired

#### 2. Tests Pass Locally but Fail in CI

**Possible Causes:**
- Missing environment variables (add to secrets)
- Different Ruby version (test with same version locally)
- Timezone differences (use UTC in tests)
- External API dependencies (use VCR for recording)

#### 3. Dependabot PRs Failing

**Solution:**
- Check if the failure is due to breaking changes
- Update your code to accommodate the new version
- Or add version constraints in Gemfile

#### 4. Coverage Reports Not Uploading

**Check:**
- SimpleCov is configured correctly
- Coverage file is generated at expected path
- Codecov token is set (if repo is private)

### Debugging Workflows

Add debug logging to workflows:

```yaml
- name: Debug Environment
  run: |
    echo "Ruby Version: $(ruby -v)"
    echo "Bundler Version: $(bundle -v)"
    echo "Gem Version: $(gem -v)"
    env
```

Enable debug logging:
1. Go to Settings → Secrets → Actions
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Add secret: `ACTIONS_RUNNER_DEBUG` = `true`

## 🔒 Security Considerations

### Best Practices

1. **Secret Management**
   - Never commit secrets to the repository
   - Use GitHub Secrets for sensitive data
   - Rotate API keys regularly
   - Use least-privilege principle for API keys

2. **Dependency Security**
   - Review Dependabot PRs carefully
   - Don't auto-merge security updates without testing
   - Keep `bundler-audit` database updated
   - Consider using `bundle lock --add-platform` for consistency

3. **Workflow Security**
   - Use exact action versions (not `@main` or `@latest`)
   - Review workflow changes in PRs carefully
   - Limit workflow permissions when possible
   - Use environment protection rules for production

### Security Scanning

The CI workflow includes:
- **bundler-audit:** Checks for known CVEs in dependencies
- **Brakeman:** Rails-specific security scanner (if applicable)

To run security checks locally:
```bash
# Install tools
gem install bundler-audit brakeman

# Run audits
bundle-audit check --update
brakeman  # If Rails app
```

## 📊 Status Badges

Add these badges to your README.md:

```markdown
![CI](https://github.com/nickMarz/Ruby-Anvil/workflows/CI/badge.svg)
![Gem Version](https://badge.fury.io/rb/anvil-ruby.svg)
![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-red.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
```

## 🤝 Contributing

When contributing:
1. Ensure all CI checks pass
2. Add tests for new features
3. Update documentation as needed
4. Follow the Ruby style guide (enforced by RuboCop)

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Ruby Setup Action](https://github.com/ruby/setup-ruby)
- [RubyGems Publishing Guide](https://guides.rubygems.org/publishing/)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Anvil API Documentation](https://www.useanvil.com/docs/)

## 📝 Workflow Maintenance

### Updating Ruby Versions

When new Ruby versions are released:

1. Update `.github/workflows/ci.yml`:
   ```yaml
   matrix:
     ruby-version: ['2.7', '3.0', '3.1', '3.2', '3.3', '3.4']  # Add new version
   ```

2. Update `anvil-ruby.gemspec`:
   ```ruby
   spec.required_ruby_version = '>= 2.5.0'  # Update if dropping old versions
   ```

3. Update `.ruby-version` for local development

### Monitoring Workflow Usage

Check your workflow usage:
- Go to Settings → Billing & plans → Usage this month
- Free tier: 2,000 minutes/month for private repos
- Unlimited for public repos

---

*Last updated: January 2024*
*Maintained by: Anvil Ruby Team*