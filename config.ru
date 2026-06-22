# config.ru
# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
require 'rails'

require 'action_controller/railtie'
require 'action_view/railtie'

require_relative 'lib/unmagic/icon'
require_relative 'lib/unmagic/icon/library/source'
require_relative 'lib/unmagic/icon/web'

# Libraries to download into tmp/icons and browse. Add/remove keys as you like
# (see `rails unmagic:icons:download` or Source.all for the full list).
ICON_LIBRARIES = %w[devicons lucide phosphor bootstrap-icons]
ICON_BASE_PATH = File.join(__dir__, 'tmp/icons')

ICON_LIBRARIES.each do |key|
  Unmagic::Icon::Library::Source.find(key).new.download(
    target_dir: File.join(ICON_BASE_PATH, Unmagic::Icon::Library::Source.find(key).dir)
  )
end

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

    routes.append do
      mount Unmagic::Icon::Web => "/unmagic/icons"
      root to: redirect("/unmagic/icons")
    end
  end
end

IconWebSandbox::Application.initialize!
run IconWebSandbox::Application
