# frozen_string_literal: true

require_relative "lib/rubyrana/version"

Gem::Specification.new do |spec|
  spec.name          = "rubyrana"
  spec.version       = Rubyrana::VERSION
  spec.authors       = ["Rubyrana Contributors"]
  spec.email         = ["hello@rubyrana.dev"]

  spec.summary       = "Build production-ready AI agents in Ruby"
  spec.description   = "Rubyrana is a model-driven Ruby SDK for building AI agents."
  spec.homepage      = "https://github.com/your-org/rubyrana"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir[
    "lib/**/*",
    "README.md",
    "REPORT.md",
    "LICENSE",
    "NOTICE",
    "CHANGELOG.md",
    "docs/**/*",
    "examples/**/*"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 2.0"
  spec.add_dependency "json", ">= 2.0"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rubocop", ">= 1.0"
  spec.add_development_dependency "dotenv", ">= 2.0"
end
