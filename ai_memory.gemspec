# frozen_string_literal: true

require_relative "lib/ai_memory/version"

Gem::Specification.new do |spec|
  spec.name = "ai_memory"
  spec.version = AiMemory::VERSION
  spec.authors = ["sandip parida"]
  spec.email = ["62925499+princetechs@users.noreply.github.com"]

  spec.summary = "Intelligent memory management system for AI chat applications with vector database support"
  spec.description = "AiMemory provides non-blocking, intelligent memory extraction and retrieval for AI chat applications. Supports Redis, PGVector, and Pinecone for semantic search with automatic fallback to JSON storage."
  spec.homepage = "https://github.com/princetechs/ai_memory"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/princetechs/ai_memory"
  spec.metadata["changelog_uri"] = "https://github.com/princetechs/ai_memory/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.match?(/\.gem$/) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "digest", "~> 3.1"
  
  # Optional AI dependencies
  spec.add_dependency "ruby-openai", "~> 8.1"
  spec.add_dependency "raix", "~> 1.0"
  
  # Optional vector database dependencies
  spec.add_dependency "redis", "~> 5.0", ">= 5.0.0"
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "pg", "~> 1.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
