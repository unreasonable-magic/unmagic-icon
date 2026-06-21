# frozen_string_literal: true

require_relative "lib/unmagic/icon/version"

Gem::Specification.new do |spec|
  spec.name        = "unmagic-icon"
  spec.version     = Unmagic::Icon::VERSION
  spec.authors     = ["Keith Pitt"]
  spec.email       = ["keith@unreasonable-magic.com"]
  spec.summary     = "Inline SVG icons for Rails, with downloadable icon libraries"
  spec.description = "Render SVG icons inline in Rails views, resolve them through library/name references and aliases, and download popular icon sets (Heroicons, Lucide, Tabler, Feather, and more)"
  spec.homepage    = "https://github.com/unreasonable-magic/unmagic-icon"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "nokogiri", ">= 1.8.5"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rake", "~> 13.0"
end
