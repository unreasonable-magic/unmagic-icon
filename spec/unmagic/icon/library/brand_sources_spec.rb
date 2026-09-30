# frozen_string_literal: true

require "spec_helper"
require "unmagic/icon/library/source"
require "unmagic/icon/web"
require "stringio"

RSpec.describe "Brand library downloads" do
  Source = Unmagic::Icon::Library::Source
  SOURCES = {
    "svg-logos" => {
      root: "logos-37a6b807fd71c622efea27a9309b5d4edc792969", directory: "logos",
      icons: %w[microsoft-power-bi aws-cloudformation slim], notices: %w[LICENSE.txt README.md logos.json]
    },
    "homarr-icons" => {
      root: "dashboard-icons-c716eb6798576923fa08e9b3e4125173148994ed", directory: "svg",
      icons: %w[dagster-light dagster-dark powerbi], notices: %w[LICENSE README.md]
    },
    "carbon-pictograms" => {
      root: "package", directory: "svg", icons: %w[ibm--cloud], notices: %w[LICENSE README.md]
    }
  }.freeze

  def archive(entries)
    buffer = StringIO.new("".b)
    Zlib::GzipWriter.wrap(buffer) do |gzip|
      Gem::Package::TarWriter.new(gzip) do |tar|
        entries.each do |name, contents|
          tar.add_file_simple(name, 0o644, contents.bytesize) { |io| io.write(contents) }
        end
      end
    end
    buffer.string
  end

  # Distinct payloads ensure variants never silently overwrite one another.
  def svg(name)
    %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><defs><linearGradient id="paint"><stop stop-color="#ffcc00"/></linearGradient></defs><path data-product="#{name}" fill="url(#paint)" d="M1 1h20v20H1z"/></svg>)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @base = Pathname(dir)
      example.run
    end
  end

  before do
    # No live requests, including accidentally introduced extra downloads.
    allow(Net::HTTP).to receive(:new).and_raise("Unexpected network request")
  end

  SOURCES.each do |key, layout|
    context key do
      let(:source_class) { Source.find(key) }
      let(:source) { source_class.new }
      let(:target) { @base.join(key) }
      let(:entries) do
        files = layout[:icons].to_h { |name| [ "#{layout[:root]}/#{layout[:directory]}/#{name}.svg", svg(name) ] }
        layout[:notices].each { |name| files["#{layout[:root]}/#{name}"] = "Upstream #{name}: preserve this notice" }
        files["#{layout[:root]}/png/ignored.png"] = "not an SVG"
        files["#{layout[:root]}/src/svg/ibm--cloud.svg"] = "wrong duplicate"
        files
      end

      def stub_archive(body, status: "200")
        uri = URI(source_class.url)
        response = Net::HTTPResponse.new("1.1", status, "fixture")
        allow(response).to receive(:body).and_return(body)
        http = instance_double(Net::HTTP)
        expect(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http)
        expect(http).to receive(:use_ssl=).with(true)
        expect(http).to receive(:request) do |request|
          expect(request).to be_a(Net::HTTP::Get)
          expect(request.path).to eq(uri.request_uri)
          response
        end
      end

      it "downloads the pinned layout, retains notices and discovers exact qualified references" do
        stub_archive(archive(entries))
        source.download(target_dir: target)
        use_icon_paths(@base)

        expect(Source.all).to include(source_class)
        expect(source_class.url).not_to match(%r{/(main|master|latest)(/|$)})
        expect(Unmagic::Icon.libraries.map(&:name)).to eq([ key ])
        expect(Unmagic::Icon.libraries.first.icons.map(&:name)).to match_array(layout[:icons].map { |name| "#{key}/#{name}" })
        layout[:notices].each do |name|
          expect(target.join(name).read).to eq(entries["#{layout[:root]}/#{name}"])
        end
        manifest = JSON.parse(target.join("manifest.json").read)
        expect(manifest).to include("name" => key, "archive" => source_class.url)
        expect(manifest["provider"]).not_to be_empty
        expect(manifest["license"]).not_to be_empty
        expect(manifest).not_to have_key("aliases")
        expect(manifest).not_to have_key("default")

        layout[:icons].each do |name|
          icon = Unmagic::Icon.find("#{key}/#{name}")
          expect(icon.name).to eq("#{key}/#{name}")
          expect(File.read(icon.path)).to eq(svg(name))
          rendered = icon.render(class: "preview", "aria-label": 'A "brand"')
          expect(rendered).to be_html_safe
          expect(rendered).to include('class="unmagic-icon preview"', "data-unmagic-icon=\"#{key}/#{name}\"", 'aria-label="A &quot;brand&quot;"')
          expect(rendered).to include('viewBox="0 0 32 32"', '<linearGradient id="paint">', 'fill="url(#paint)"', "data-product=\"#{name}\"")
        end
        expect { Unmagic::Icon.find("#{key}/unknown-product") }.to raise_error(Unmagic::Icon::IconNotFoundError)
      end

      it "renders required matches through the existing browser app" do
        stub_archive(archive(entries))
        source.download(target_dir: target)
        use_icon_paths(@base)
        response = Rack::MockRequest.new(Unmagic::Icon::Web.new).get("/?library=#{key}&format=fragment")
        expect(response.status).to eq(200)
        layout[:icons].each { |name| expect(response.body).to include("data-unmagic-icon=\"#{key}/#{name}\"") }
      end

      it "leaves existing downloads alone unless forced" do
        write_svgs(target, "saved-reference")
        source.download(target_dir: target)
        expect(target.join("saved-reference.svg").read).to eq(FixtureHelpers::SAMPLE_SVG)
        stub_archive(archive(entries))
        source.download(target_dir: target, force: true)
        expect(target.join("#{layout[:icons].first}.svg")).to exist
        expect(target.join("saved-reference.svg")).to exist
      end

      it "rejects missing license files before creating an install directory" do
        entries.delete("#{layout[:root]}/#{layout[:notices].first}")
        stub_archive(archive(entries))
        expect { source.download(target_dir: target) }.to raise_error(Source::ExtractionError, /Missing required attribution/)
        expect(target).not_to exist
      end

      it "reports download failures without creating an install directory" do
        stub_archive("not found", status: "404")
        expect { source.download(target_dir: target) }.to raise_error(Source::DownloadError, /HTTP 404/)
        expect(target).not_to exist
      end

      it "retains archive traversal protection" do
        stub_archive(archive("../escaped.svg" => svg("escaped")))
        expect { source.download(target_dir: target) }.to raise_error(Source::ExtractionError, /escapes extraction directory/)
        expect(target).not_to exist
      end
    end
  end

  it "preserves existing references and does not infer misleading product aliases" do
    write_svgs(@base.join("lucide"), "check")
    write_svgs(@base.join("svg-logos"), "slim", "microsoft", "aws")
    write_svgs(@base.join("homarr-icons"), "dagster-light", "dagster-dark")
    use_icon_paths(@base)
    expect(Unmagic::Icon.find("lucide/check").render).to include('data-unmagic-icon="lucide/check"')
    expect(Unmagic::Icon.find("svg-logos/slim").name).to eq("svg-logos/slim")
    %w[svg-logos/ruby-slim svg-logos/powerbi svg-logos/cloudformation homarr-icons/dagster].each do |reference|
      expect { Unmagic::Icon.find(reference) }.to raise_error(Unmagic::Icon::IconNotFoundError)
    end
  end
end
