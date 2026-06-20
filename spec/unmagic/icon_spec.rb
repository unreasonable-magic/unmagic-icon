# frozen_string_literal: true

require "spec_helper"

RSpec.describe Unmagic::Icon do
  describe ".parse_reference" do
    it "splits a library/name reference" do
      expect(described_class.parse_reference("material/ruby")).to eq([ "material", "ruby" ])
    end

    it "tolerates emoji-style colon decoration" do
      expect(described_class.parse_reference(":material/ruby:")).to eq([ "material", "ruby" ])
    end

    it "keeps nested library paths intact" do
      expect(described_class.parse_reference("heroicons/24-outline/star"))
        .to eq([ "heroicons/24-outline", "star" ])
    end
  end

  describe ".find" do
    around do |example|
      Dir.mktmpdir do |root|
        write_svgs(File.join(root, "material"), "ruby", "file")
        write_manifest(File.join(root, "material"), { "default" => "file", "aliases" => { "*.rb" => "ruby" } })
        use_icon_paths(root)
        example.run
      end
    end

    it "resolves through the alias index via a full reference" do
      expect(described_class.find("material/app.rb").name).to eq("material/ruby")
    end

    it "accepts a colon-decorated reference" do
      expect(described_class.find(":material/ruby:").name).to eq("material/ruby")
    end
  end

  describe "#render" do
    let(:svg_path) do
      file = File.join(@dir, "foo.svg")
      File.write(file, FixtureHelpers::SAMPLE_SVG)
      file
    end

    around do |example|
      Dir.mktmpdir { |dir| @dir = dir; example.run }
    end

    it "inlines svg assets as html-safe markup" do
      html = described_class.new(name: "x/foo", path: svg_path).render
      expect(html).to include("<svg")
      expect(html).to be_html_safe
    end

    it "raises for asset kinds it can't render" do
      icon = described_class.new(name: "x/foo", path: File.join(@dir, "foo.png"))
      expect { icon.render }.to raise_error(Unmagic::Icon::Error, /render/)
    end
  end

  describe "#to_svg caching" do
    around do |example|
      Dir.mktmpdir { |dir| @dir = dir; example.run }
    end

    it "returns the same cached buffer when no options are passed" do
      file = File.join(@dir, "foo.svg")
      File.write(file, FixtureHelpers::SAMPLE_SVG)
      icon = described_class.new(name: "x/foo", path: file)

      expect(icon.to_svg).to equal(icon.to_svg)
    end
  end
end
