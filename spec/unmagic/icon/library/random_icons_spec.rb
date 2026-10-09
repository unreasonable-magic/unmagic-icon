# frozen_string_literal: true

require "spec_helper"
require "unmagic/icon/library/source"

RSpec.describe Unmagic::Icon::Library::Source::RandomIcons do
  it "installs colored SVGs and per-asset licenses from the main archive" do
    Dir.mktmpdir do |dir|
      base = Pathname(dir)
      archive = base.join("pack.tgz")
      svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#ef4444" d="M0 0h24v24H0z"/></svg>'
      entries = {
        "icons/example.svg" => svg,
        "icons/ignored.png" => "ignored",
        "README.md" => "Pack instructions",
        "ATTRIBUTION.md" => "Asset attribution",
        "sources.json" => '{"assets":[]}',
        "licenses/example.txt" => "Asset license"
      }
      Zlib::GzipWriter.open(archive.to_s) do |gzip|
        Gem::Package::TarWriter.new(gzip) do |tar|
          entries.each do |name, contents|
            tar.add_file_simple("random-icons-main/#{name}", 0o644, contents.bytesize) { |io| io.write(contents) }
          end
        end
      end

      source = described_class.new
      allow(source).to receive(:download_file).with(described_class.url, anything) do |_, destination|
        FileUtils.cp(archive, destination)
      end
      target = base.join("installed/random-icons")
      source.download(target_dir: target)
      use_icon_paths(base.join("installed"))

      expect(Unmagic::Icon::Library::Source.find("random-icons")).to eq(described_class)
      expect(Unmagic::Icon.find("random-icons/example").render).to include('fill="#ef4444"')
      expect(target.join("example.svg").read).to eq(svg)
      expect(target.join("ignored.png")).not_to exist
      expect(target.join("ATTRIBUTION.md").read).to eq("Asset attribution")
      expect(target.join("licenses/example.txt").read).to eq("Asset license")
      expect(target.join("sources.json").read).to eq('{"assets":[]}')
      expect(JSON.parse(target.join("manifest.json").read)).to include("revision" => "main")

      source.download(target_dir: target, force: true)
      expect(target.join("licenses/example.txt").read).to eq("Asset license")
    end
  end
end
