# frozen_string_literal: true

require "spec_helper"

RSpec.describe Unmagic::Icon::Library do
  around do |example|
    Dir.mktmpdir do |root|
      write_svgs(File.join(root, "files"), "file", "ruby", "react", "react_ts", "thumbsup", "docker")
      write_manifest(File.join(root, "files"), {
        "name" => "files",
        "default" => "file",
        "aliases" => {
          "*.rb" => "ruby",
          "*.tsx" => "react_ts",
          "*.test.tsx" => "react",
          "Dockerfile" => "docker",
          ":+1:" => "thumbsup"
        }
      })
      write_svgs(File.join(root, "plain"), "star")

      use_icon_paths(root)
      example.run
    end
  end

  def files = Unmagic::Icon::Library::Registry.find("files")

  it "finds an icon by its exact name" do
    expect(files.find("ruby").name).to eq("files/ruby")
  end

  it "resolves a glob alias by extension" do
    expect(files.find("app.rb").name).to eq("files/ruby")
  end

  it "matches aliases case-insensitively" do
    expect(files.find("App.RB").name).to eq("files/ruby")
    expect(files.find("dockerfile").name).to eq("files/docker")
  end

  it "prefers the longest matching pattern" do
    expect(files.find("button.tsx").name).to eq("files/react_ts")
    expect(files.find("button.test.tsx").name).to eq("files/react")
  end

  it "resolves an exact filename alias" do
    expect(files.find("Dockerfile").name).to eq("files/docker")
  end

  it "resolves an emoji-style shortcode alias" do
    expect(files.find(":+1:").name).to eq("files/thumbsup")
  end

  it "falls back to the manifest default" do
    expect(files.find("mystery.xyz").name).to eq("files/file")
  end

  it "raises when nothing matches and there is no default" do
    plain = Unmagic::Icon::Library::Registry.find("plain")
    expect { plain.find("nope") }.to raise_error(Unmagic::Icon::IconNotFoundError)
  end

  it "exposes per-entry aliases from the manifest's entries" do
    Dir.mktmpdir do |root|
      write_svgs(File.join(root, "emoji"), "thumbsup")
      write_manifest(File.join(root, "emoji"), {
        "name" => "emoji",
        "entries" => [ { "name" => "thumbsup", "aliases" => [ ":+1:", ":thumbsup:" ] } ]
      })
      use_icon_paths(root)

      emoji = Unmagic::Icon::Library::Registry.find("emoji")
      expect(emoji.find(":thumbsup:").name).to eq("emoji/thumbsup")
      expect(emoji.find(":+1:").name).to eq("emoji/thumbsup")
    end
  end
end
