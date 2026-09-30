# frozen_string_literal: true

require "spec_helper"
require "unmagic/icon/library/source"
require "unmagic/icon/web"
require "zip"

RSpec.describe Unmagic::Icon::Library::Source::AwsArchitectureIcons do
  let(:source) { described_class.new }
  let(:products) do
    {
      "Arch_Management-Tools" => %w[AWS-CloudFormation],
      "Arch_Developer-Tools" => %w[AWS-Cloud-Development-Kit],
      "Arch_Analytics" => %w[Amazon-SageMaker],
      "Arch_Artificial-Intelligence" => %w[Amazon-SageMaker-AI Amazon-SageMaker-Studio-Lab Amazon-SageMaker-Ground-Truth]
    }
  end
  let(:entries) do
    products.each_with_object({}) do |(category, names), files|
      names.each do |name|
        files["Architecture-Service-Icons_07312026/#{category}/64/Arch_#{name}_64.svg"] = svg(name)
      end
    end.merge(
      "Architecture-Service-Icons_07312026/Arch_Analytics/48/Arch_Amazon-SageMaker_48.svg" => svg("wrong-size"),
      "Resource-Icons_07312026/Res_Analytics/Res_Amazon-SageMaker_48.svg" => svg("resource"),
      "Category-Icons_07312026/Arch-Category_64/Arch-Category_Analytics_64.svg" => svg("category"),
      "__MACOSX/Architecture-Service-Icons_07312026/Arch_Analytics/64/._Arch_Amazon-SageMaker_64.svg" => "metadata",
      "Architecture-Service-Icons_07312026/Arch_Analytics/64/Arch_Amazon-SageMaker_64.png" => "raster"
    )
  end

  def svg(name)
    %(<svg viewBox="0 0 64 64"><path data-product="#{name}" fill="#8C4FFF" d="M1 1h62v62H1z"/></svg>)
  end

  def zip(entries)
    Zip::OutputStream.write_buffer do |output|
      entries.each do |name, content|
        output.put_next_entry(name)
        output.write(content)
      end
    end.string
  end

  def stub_download(body, status: "200", checksum: true)
    stub_const("#{described_class}::SHA256", Digest::SHA256.hexdigest(body)) if checksum
    uri = URI(described_class.url)
    http = instance_double(Net::HTTP)
    response = Net::HTTPResponse.new("1.1", status, "fixture")
    allow(response).to receive(:body).and_return(body)
    expect(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http)
    expect(http).to receive(:use_ssl=).with(true)
    expect(http).to receive(:request) do |request|
      expect(request.path).to eq(uri.request_uri)
      response
    end
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @base = Pathname(dir)
      @target = @base.join("aws-architecture-icons")
      example.run
    end
  end

  before do
    allow(Net::HTTP).to receive(:new).and_raise("Unexpected network request")
  end

  it "downloads only service SVGs and renders each distinct product through discovery and the gallery" do
    stub_download(zip(entries))
    source.download(target_dir: @target)
    use_icon_paths(@base)
    names = products.values.flatten.map { |product| "Arch_#{product}_64" }
    expect(Unmagic::Icon::Library::Source.find("aws-architecture-icons")).to eq(described_class)
    expect(Unmagic::Icon.libraries.first.icons.map(&:name)).to match_array(names.map { |name| "aws-architecture-icons/#{name}" })
    names.each do |name|
      reference = "aws-architecture-icons/#{name}"
      icon = Unmagic::Icon.find(reference)
      expect(File.read(icon.path)).to eq(svg(name.delete_prefix("Arch_").delete_suffix("_64")))
      rendered = icon.render(class: "size-6", "aria-label": 'AWS "service"')
      expect(rendered).to be_html_safe
      expect(rendered).to include('viewBox="0 0 64 64"', 'fill="#8C4FFF"', 'class="unmagic-icon size-6"', 'aria-label="AWS &quot;service&quot;"')
      expect(rendered).to include("data-unmagic-icon=\"#{reference}\"")
    end
    response = Rack::MockRequest.new(Unmagic::Icon::Web.new).get("/?library=aws-architecture-icons&search=SageMaker&format=fragment")
    expect(response.status).to eq(200)
    expect(response.headers["x-total-count"]).to eq("4")
    names.grep(/SageMaker/).each { |name| expect(response.body).to include("data-unmagic-icon=\"aws-architecture-icons/#{name}\"") }
    expect { Unmagic::Icon.find("aws-architecture-icons/sagemaker") }.to raise_error(Unmagic::Icon::IconNotFoundError)
    manifest = JSON.parse(@target.join("manifest.json").read)
    expect(manifest).to include("version" => "2026-07-31", "archive" => described_class.url, "license" => "Proprietary — AWS usage terms")
    expect(manifest).not_to have_key("aliases")
    expect(manifest).not_to have_key("default")
    expect(@target.join("ATTRIBUTION.txt").read).to include("Amazon Web Services", "https://aws.amazon.com/terms/", "not assets\nlicensed under this gem's MIT license")
  end

  it "rejects a changed archive before installing anything" do
    stub_download(zip(entries), checksum: false)
    expect { source.download(target_dir: @target) }.to raise_error(described_class::DownloadError, /checksum mismatch/)
    expect(@target).not_to exist
  end

  it "reports HTTP errors before installing anything" do
    stub_download("missing", status: "404")
    expect { source.download(target_dir: @target) }.to raise_error(described_class::DownloadError, /HTTP 404/)
    expect(@target).not_to exist
  end

  it "rejects ZIP traversal even in a checksum-verified archive" do
    stub_download(zip("../escaped.svg" => svg("escape")))
    expect { source.download(target_dir: @target) }.to raise_error(described_class::ExtractionError, /escapes extraction directory/)
    expect(@target).not_to exist
  end

  it "preserves saved references on skips and forced downloads" do
    write_svgs(@target, "saved")
    source.download(target_dir: @target)
    stub_download(zip(entries))
    source.download(target_dir: @target, force: true)
    use_icon_paths(@base)
    expect(Unmagic::Icon.find("aws-architecture-icons/saved").render).to include('data-unmagic-icon="aws-architecture-icons/saved"')
    expect(Unmagic::Icon.find("aws-architecture-icons/Arch_AWS-CloudFormation_64").render).to include('data-product="AWS-CloudFormation"')
  end
end
