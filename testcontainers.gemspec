# frozen_string_literal: true

require_relative "core/lib/testcontainers/version"

Gem::Specification.new do |spec|
  spec.name = "testcontainers"
  spec.version = Testcontainers::VERSION
  spec.authors = ["Guillermo Iguaran"]
  spec.email = ["guilleiguaran@gmail.com"]

  spec.summary = "Testcontainers for Ruby."
  spec.description = "Testcontainers makes it easy to create and clean up container-based dependencies for automated tests."
  spec.homepage = "https://github.com/guilleiguaran/testcontainers-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.files = []

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "testcontainers-core", Testcontainers::VERSION

  # For docs
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.3"
end
