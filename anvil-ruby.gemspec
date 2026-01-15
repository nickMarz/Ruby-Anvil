
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anvil/version'

Gem::Specification.new do |spec|
  spec.name          = 'anvil-ruby'
  spec.version       = Anvil::VERSION
  spec.authors       = ['Nick Marazzo']
  spec.email         = ['nick.marazzo@kodehealth.com']

  spec.summary       = 'Ruby client for the Anvil API - document automation and e-signatures'
  spec.description   = <<~DESC
    Official Ruby client for the Anvil API. Anvil is a suite of tools for
    managing document workflows including PDF filling, PDF generation from HTML/Markdown,
    e-signatures, and webhooks. Built with zero runtime dependencies and designed
    to be Rails-friendly while remaining framework agnostic.
  DESC
  spec.homepage      = 'https://github.com/nickMarz/Ruby-Anvil'
  spec.license       = 'MIT'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/nickMarz/Ruby-Anvil',
    'changelog_uri' => 'https://github.com/nickMarz/Ruby-Anvil/blob/main/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/nickMarz/Ruby-Anvil/issues',
    'documentation_uri' => 'https://www.rubydoc.info/gems/anvil-ruby',
    'rubygems_mfa_required' => 'true'
  }

  # Ruby version requirement
  spec.required_ruby_version = '>= 2.5.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/}) ||
        f.match(%r{^\.}) ||
        f.match(%r{^(Gemfile|Rakefile)$})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # No runtime dependencies! Pure Ruby with Net::HTTP
  # This is intentional - we want zero runtime dependencies

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'yard', '~> 0.9'

  # Optional dependency for multipart file uploads
  # Users can add this to their Gemfile if they need file upload functionality
  spec.add_development_dependency 'multipart-post', '~> 2.3'
end
