# frozen_string_literal: true

module Unmagic
  class Icon
    class Engine < ::Rails::Engine
      isolate_namespace Unmagic::Icon

      initializer "unmagic_icon.init" do
        unless Unmagic::Icon.initialized?
          Unmagic::Icon.init do |config|
            paths = [ Rails.root.join("app", "assets", "icons").to_s ]

            # Also look for icons in engines
            Rails.application.railties.select do |r|
              r.is_a?(Rails::Engine) && r.class != Rails::Application
            end.each do |engine|
              engine_path = engine.root.join("app", "assets", "icons")
              next unless engine_path.exist?

              prefix = engine.class.name.underscore.gsub(%r{/engine$}, "").tr("/", "_")
              paths << "#{prefix}:#{engine_path}"
            end

            config.paths = paths
          end
        end
      end
    end
  end
end
