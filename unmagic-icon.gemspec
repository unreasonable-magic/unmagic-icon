# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'unmagic-icon'
  spec.version = '0.1.0'
  spec.authors = [ 'Unmagic' ]
  spec.email = [ 'hello@unmagic.com' ]

  spec.summary = 'Icon management system with usage tracking'
  spec.description = 'A Rails gem for managing SVG icons with automatic usage discovery and validation'
  spec.homepage = 'https://github.com/unmagic/unmagic-icon'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir['{lib}/**/*', 'LICENSE', 'README.md']
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'activesupport', '>= 7.0.0'
  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'railties', '>= 7.0.0'
  spec.add_dependency 'nokogiri', '>= 1.8.5'
end
