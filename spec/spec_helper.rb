# frozen_string_literal: true

require "unmagic/icon"
require "json"
require "tmpdir"
require "fileutils"
require "pathname"

# Minimal helpers for building throwaway icon libraries on disk.
module FixtureHelpers
  SAMPLE_SVG = %(<svg viewBox="0 0 24 24"><path d="M1 1h22v22H1z"/></svg>)

  def write_svgs(dir, *names)
    FileUtils.mkdir_p(dir)
    names.each { |name| File.write(File.join(dir, "#{name}.svg"), SAMPLE_SVG) }
  end

  def write_manifest(dir, manifest)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "manifest.json"), JSON.generate(manifest))
  end

  def use_icon_paths(*paths)
    Unmagic::Icon.configuration.paths = paths.map(&:to_s)
    Unmagic::Icon::Library::Registry.reset!
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers

  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.after do
    Unmagic::Icon::Library::Registry.reset!
    Unmagic::Icon.configuration.paths = []
  end
end
