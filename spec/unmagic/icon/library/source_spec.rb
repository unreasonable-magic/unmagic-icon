# frozen_string_literal: true

require "spec_helper"
require "unmagic/icon/library/source"

RSpec.describe Unmagic::Icon::Library::Source do
  describe ".find / .all" do
    it "looks a source up by key" do
      expect(described_class.find("heroicons")).to eq(Unmagic::Icon::Library::Source::Heroicons)
      expect(described_class.find("material-file-icons")).to eq(Unmagic::Icon::Library::Source::MaterialFileIcons)
    end

    it "raises for an unknown library" do
      expect { described_class.find("nope") }.to raise_error(ArgumentError, /Unknown library/)
    end

    it "registers every library subclass" do
      expect(described_class.all).to include(
        Unmagic::Icon::Library::Source::Lucide,
        Unmagic::Icon::Library::Source::Silk,
        Unmagic::Icon::Library::Source::MaterialFileIcons,
        Unmagic::Icon::Library::Source::ColouredIcons,
        Unmagic::Icon::Library::Source::BootstrapIcons,
        Unmagic::Icon::Library::Source::Octicons,
        Unmagic::Icon::Library::Source::Iconoir,
        Unmagic::Icon::Library::Source::MaterialDesignIcons,
        Unmagic::Icon::Library::Source::Phosphor
      )
    end
  end

  describe "metadata DSL" do
    it "exposes per-library metadata" do
      material = Unmagic::Icon::Library::Source::MaterialFileIcons
      expect(material.key).to eq(:"material-file-icons")
      expect(material.title).to eq("Material File Icons")
      expect(material.archive).to eq(:tgz)
      expect(material.dir).to eq("material")
    end

    it "defaults the on-disk dir to the key" do
      expect(Unmagic::Icon::Library::Source::Heroicons.dir).to eq("heroicons")
    end
  end

  describe Unmagic::Icon::Library::Source::MaterialFileIcons do
    around do |example|
      Dir.mktmpdir do |source|
        @source = Pathname(source)
        @target = Pathname(Dir.mktmpdir)
        example.run
        FileUtils.remove_entry(@target)
      end
    end

    before do
      FileUtils.mkdir_p(@source.join("package", "dist"))
      File.write(@source.join("package", "dist", "material-icons.json"), JSON.generate({
        "file" => "file",
        "iconDefinitions" => {
          "ruby" => { "iconPath" => "./../icons/ruby.svg" },
          "docker" => { "iconPath" => "./../icons/docker.svg" },
          "latex" => { "iconPath" => "./../icons/latex.clone.svg" }
        },
        "fileExtensions" => { "rb" => "ruby", "tex" => "latex" },
        "fileNames" => { "dockerfile" => "docker" }
      }))

      # The extracted icons as they land on disk (clone keeps its on-disk name).
      %w[ruby docker file].each { |name| File.write(@target.join("#{name}.svg"), FixtureHelpers::SAMPLE_SVG) }
      File.write(@target.join("latex.clone.svg"), FixtureHelpers::SAMPLE_SVG)
    end

    def generate
      described_class.new.send(:write_manifest, @source.to_s, @target)
    end

    it "writes a manifest of extension and filename aliases" do
      generate
      manifest = JSON.parse(File.read(@target.join("manifest.json")))

      expect(manifest["default"]).to eq("file")
      expect(manifest["aliases"]).to include("*.rb" => "ruby", "*.tex" => "latex", "dockerfile" => "docker")
    end

    it "renames clone files to their clean icon name" do
      generate
      expect(@target.join("latex.svg")).to exist
      expect(@target.join("latex.clone.svg")).not_to exist
    end

    it "produces a library that resolves files end-to-end" do
      generate
      library = Unmagic::Icon::Library.new(name: "material", path: @target)

      expect(library.find("app.rb").name).to eq("material/ruby")
      expect(library.find("paper.tex").name).to eq("material/latex")
      expect(library.find("Dockerfile").name).to eq("material/docker")
      expect(library.find("whatever.unknown").name).to eq("material/file")
    end
  end
end
