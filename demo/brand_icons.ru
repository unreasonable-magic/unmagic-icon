# frozen_string_literal: true

# Run: bundle exec rackup demo/brand_icons.ru -p 5701 -o 127.0.0.1
# Open http://localhost:5701/demo and click Replay to repeat the visible checks.
require "bundler/setup"
require_relative "../lib/unmagic/icon"
require_relative "../lib/unmagic/icon/library/source"
require_relative "../lib/unmagic/icon/web"

base = File.expand_path("../tmp/brand-demo", __dir__)
%w[svg-logos dashboard-icons carbon-pictograms lucide].each do |key|
  Unmagic::Icon::Library::Source.find(key).new.download(target_dir: File.join(base, key))
end
Unmagic::Icon.configuration.paths = [ base ]

map "/demo" do
  run lambda { |_env|
    [ 200, { "content-type" => "text/html; charset=utf-8" }, [ File.read(File.join(__dir__, "brand_icons.html")) ] ]
  }
end
map "/" do
  run Unmagic::Icon::Web
end
