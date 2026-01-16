# Instructions for Claude

## 🚀 Quick Start for New Sessions

When starting a new session with this project, please:

1. **Read the project notes**:
   ```
   Read .claude-project-notes.md
   ```

2. **Check current status**:
   ```bash
   git status
   git log -1
   ```

3. **Understand the project**:
   - This is the Anvil Ruby gem for document automation
   - GitHub Actions are fully configured for CI/CD
   - Tests should always pass before committing

## 📝 Important Context

### GitHub Actions Setup (Completed Jan 15, 2024)
- ✅ CI pipeline (`.github/workflows/ci.yml`)
- ✅ Gem publishing (`.github/workflows/gem-push.yml`)
- ✅ Dependabot configuration
- ✅ Full documentation in `.github/workflows/README.md`

### Required Secrets
- `RUBYGEMS_AUTH_TOKEN` - Must be added to GitHub for gem publishing
- `ANVIL_API_KEY` - Optional, for running tests

### Project Conventions
- Use RuboCop for style (`bundle exec rubocop`)
- Write tests for all new features (`bundle exec rspec`)
- Zero runtime dependencies (except base64 for Ruby 3.4+)
- Follow semantic versioning

## 🎯 Common Tasks

### Before ANY commit:
```bash
bundle exec rubocop
bundle exec rspec
```

### To release a new version:
1. Update `lib/anvil/version.rb`
2. Update `CHANGELOG.md`
3. Commit and tag: `git tag v0.x.x`
4. Push: `git push origin main --tags`

### To run CI locally:
```bash
bundle exec rubocop           # Linting
bundle exec rspec             # Tests
bundle-audit check --update   # Security
gem build *.gemspec          # Build
```

## 🔧 Development Workflow

1. **Always use TodoWrite tool** for multi-step tasks
2. **Run tests** before committing changes
3. **Check CI status** after pushing
4. **Document** any new features or changes

## 👤 User Preferences (Nick Marazzo)

- Prefers practical, working solutions
- Values comprehensive documentation
- Likes Ruby best practices and idiomatic code
- Appreciates proactive error handling
- Wants CI/CD automation for everything

## 📁 Key Files

- `.github/workflows/` - GitHub Actions workflows
- `lib/anvil/` - Main gem code
- `spec/` - Test files
- `examples/` - Usage examples
- `.rubocop.yml` - Style configuration
- `anvil-ruby.gemspec` - Gem specification

## 🚨 Important Reminders

1. **Never** commit without running tests
2. **Always** update CHANGELOG.md for new features
3. **Check** GitHub Actions after pushing
4. **Update** documentation for API changes
5. **Test** against multiple Ruby versions locally if possible

---

*This file helps Claude understand the project context in new sessions.*
*Last updated: January 15, 2024*