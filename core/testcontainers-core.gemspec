# frozen_string_literal: true

require_relative "lib/testcontainers/version"

Gem::Specification.new do |spec|
  spec.name = "testcontainers-core"
  spec.version = Testcontainers::VERSION
  spec.authors = ["Guillermo Iguaran"]
  spec.email = ["guilleiguaran@gmail.com"]

  spec.summary = "Testcontainers for Ruby."
  spec.description = "Testcontainers makes it easy to create and clean up container-based dependencies for automated tests."
  spec.homepage = "https://github.com/testcontainers/testcontainers-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/core/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "docker-api", "~> 2.2"
  spec.add_dependency "java-properties", "~> 0.3.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-hooks", "~> 1.5"
  spec.add_development_dependency "standard", "~> 1.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
