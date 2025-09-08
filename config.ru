# config.ru
# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
require 'rails'

require 'action_controller/railtie'
require 'action_view/railtie'

require_relative 'lib/unmagic/icon'
require_relative 'lib/unmagic/icon/downloader'

ICON_LIBRARY = :silk
ICON_BASE_PATH = File.join(__dir__, 'tmp/icons')
ICON_LIBRARY_PATH = File.join(ICON_BASE_PATH, ICON_LIBRARY.to_s)
Unmagic::Icon::Downloader.download(:silk, target_dir: ICON_LIBRARY_PATH)

Unmagic::Icon.init do |config|
  config.paths = [ ICON_BASE_PATH ]
end

# Create a minimal Rails application for the icon browser
module IconWebSandbox
  class Application < Rails::Application
    config.load_defaults 8.0

    config.middleware.delete Rails::Rack::Logger
    # Disable Rack::Lint to avoid header case issues
    config.middleware.delete Rack::Lint

    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = 'dev-secret-key-change-me'
    config.public_file_server.enabled = true

    config.cache_classes = false
    config.reload_classes_only_on_change = true

    # Set the root to our gem directory so Rails.root works correctly
    config.root = __dir__

    # Override the icon search paths to use our tmp directory
    def self.override_icon_paths!
      Unmagic::Icon.define_singleton_method(:search_paths) do
        [ [ nil, Pathname.new(ICONS_PATH) ] ]
      end

      # Clear library cache and force rediscovery
      Unmagic::Icon::Library.instance_variable_set(:@libraries, nil)
    end

    routes.append do
      mount Unmagic::Icon::Web => '/'
    end
  end
end

Unmagic::Icon.preload!

# Override icon paths before initialization
IconWebSandbox::Application.override_icon_paths!

IconWebSandbox::Application.initialize!
run IconWebSandbox::Application
